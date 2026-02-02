import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import DTooltip from "discourse/float-kit/components/d-tooltip";
import { apiInitializer } from "discourse/lib/api";
import I18n from "I18n";

class InlineTip extends Component {
  @action
  preventDefault(event) {
    event.preventDefault();
  }

  <template>
    <DTooltip
      @identifier="inline-tip"
      @interactive={{true}}
      @closeOnScroll={{false}}
      @closeOnClickOutside={{true}}
    >
      <:trigger>
        <a
          class="expand-tip"
          href
          role="button"
          {{on "click" this.preventDefault}}
        >{{htmlSafe @data.triggerText}}</a>
      </:trigger>
      <:content>
        <div class="inline-tip-content">
          {{htmlSafe @data.tipContent}}
        </div>
      </:content>
    </DTooltip>
  </template>
}

export default apiInitializer("0.11.1", (api) => {
  // Register translation
  const locale = I18n.locale || I18n.currentLocale || "en";
  if (!I18n.translations[locale]) {
    I18n.translations[locale] = {};
  }
  if (!I18n.translations[locale].js) {
    I18n.translations[locale].js = {};
  }
  I18n.translations[locale].js.insert_tooltip_label = "Insert Tooltip";

  // Decorate cooked content
  api.decorateCookedElement(
    (element, helper) => {
      processTips(element, helper);
    },
    { id: "inline-tips", onlyStream: true }
  );

  // Add composer toolbar button
  const composerApi = api.composer || api;
  if (composerApi.addComposerToolbarPopupMenuOption) {
    composerApi.addComposerToolbarPopupMenuOption({
      id: "insert-tip",
      icon: "info-circle",
      label: "insert_tooltip_label",
      action(toolbarEvent) {
        insertTip(toolbarEvent, api);
      }
    });
  }
});

function insertTip(toolbarEvent, api) {
  let model = null;
  
  if (toolbarEvent) {
    model = toolbarEvent.model || 
            toolbarEvent.composer?.model || 
            toolbarEvent.controller?.model;
  }
  
  if (!model && api?.container) {
    try {
      const composer = api.container.lookup("service:composer");
      model = composer?.model;
    } catch (e) {
      // ignore
    }
  }
  
  if (!model) {
    return;
  }

  let selectedText = "";
  
  if (toolbarEvent.selected) {
    if (typeof toolbarEvent.selected === "string") {
      selectedText = toolbarEvent.selected;
    } 
    else if (typeof toolbarEvent.selected === "object") {
      selectedText = toolbarEvent.selected.value || toolbarEvent.selected.text || "";
    }
  }
  
  let triggerText = selectedText || "trigger text";
  
  const insertion = `[tip trigger="${triggerText}"]
Your tooltip content here with HTML, images, etc.
[/tip]`;

  if (typeof toolbarEvent.addText === "function") {
    toolbarEvent.addText(insertion);
  } else {
    const reply = model.reply || "";
    const selection = model.replySelection || {};
    const selectionStart = selection.start ?? model.replySelectionStart ?? reply.length;
    const selectionEnd = selection.end ?? model.replySelectionEnd ?? reply.length;
    
    if (typeof model.replaceText === "function") {
      model.replaceText(selectionStart, selectionEnd, insertion);
    } else if (typeof model.appendText === "function") {
      model.appendText(insertion);
    }
  }
}

function processTips(element, helper) {
  if (!element || element.classList.contains("inline-tips-processed")) {
    return;
  }

  if (!helper?.getModel()) {
    return;
  }

  // Look for our custom BBCode-style tags in the raw HTML
  const html = element.innerHTML;
  const tipRegex = /\[tip trigger=["']([^"']+)["']\]([\s\S]*?)\[\/tip\]/g;
  
  let match;
  const tips = [];
  
  while ((match = tipRegex.exec(html)) !== null) {
    tips.push({
      fullMatch: match[0],
      trigger: match[1],
      content: match[2].trim()
    });
  }
  
  if (tips.length === 0) {
    return;
  }
  
  // Replace each tip with the component
  let newHTML = html;
  
  tips.forEach((tip) => {
    const tipComponent = document.createElement('span');
    tipComponent.className = 'inline-tip';
    tipComponent.setAttribute('data-trigger', tip.trigger);
    tipComponent.setAttribute('data-content', tip.content);
    
    // Create a placeholder
    const placeholder = `<!--TIP_PLACEHOLDER_${Math.random().toString(36).substr(2, 9)}-->`;
    newHTML = newHTML.replace(tip.fullMatch, placeholder);
    
    // Store for later replacement
    tipComponent.setAttribute('data-placeholder', placeholder);
    
    helper.renderGlimmer(tipComponent, InlineTip, {
      triggerText: tip.trigger,
      tipContent: tip.content
    });
    
    // Replace placeholder with component
    setTimeout(() => {
      const placeholderNode = element.ownerDocument.createTreeWalker(
        element,
        NodeFilter.SHOW_COMMENT,
        null,
        false
      );
      
      let commentNode;
      while (commentNode = placeholderNode.nextNode()) {
        if (commentNode.nodeValue === placeholder.replace('<!--', '').replace('-->', '')) {
          commentNode.parentNode.replaceChild(tipComponent, commentNode);
          break;
        }
      }
    }, 0);
  });
  
  element.innerHTML = newHTML;
  element.classList.add("inline-tips-processed");
}
