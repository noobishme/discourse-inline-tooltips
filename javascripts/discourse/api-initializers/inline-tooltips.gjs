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
  // Register translation for button label
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
      icon: "tooltip-icon",
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

  // Get selected text - handle both string and object formats
  let selectedText = "";
  
  if (toolbarEvent.selected) {
    // If it's a string, use it directly
    if (typeof toolbarEvent.selected === "string") {
      selectedText = toolbarEvent.selected;
    } 
    // If it's an object, try to get the value property
    else if (typeof toolbarEvent.selected === "object") {
      selectedText = toolbarEvent.selected.value || toolbarEvent.selected.text || "";
    }
  }
  
  // Use selected text as trigger, or default placeholder
  let triggerText = selectedText || "trigger text";
  
  // Create the tooltip markup using div wrapper for rich content
  const htmlTag = "strong";
  const insertion = `<div class="inline-tip-raw" data-trigger="${triggerText}">

Tooltip content with **markdown** and <${htmlTag}>HTML</${htmlTag}>

</div>`;

  // Use addText which properly handles cursor position from toolbarEvent
  if (typeof toolbarEvent.addText === "function") {
    toolbarEvent.addText(insertion);
  } else {
    // Fallback: use model methods
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

  // Process div-based tips (for rich content)
  processDivTips(element, helper);
  
  // Also process span-based tips (for simple inline content)
  processSpanTips(element, helper);
  
  element.classList.add("inline-tips-processed");
}

function processDivTips(element, helper) {
  // Find all divs with class inline-tip-raw
  const tipDivs = element.querySelectorAll('div.inline-tip-raw');
  
  if (tipDivs.length === 0) {
    return;
  }

  tipDivs.forEach((div) => {
    // Get trigger text from data-trigger attribute
    const triggerText = div.getAttribute('data-trigger');
    
    if (!triggerText) {
      return;
    }

    // Get tooltip content from innerHTML
    const tipContent = div.innerHTML.trim();
    
    if (!tipContent) {
      return;
    }

    // Create tooltip component as inline element
    const tipComponent = document.createElement('span');
    tipComponent.className = 'inline-tip';
    
    helper.renderGlimmer(tipComponent, InlineTip, {
      triggerText: triggerText,
      tipContent: tipContent
    });

    // Replace the div with our inline tooltip
    div.parentNode.replaceChild(tipComponent, div);
  });
}

function processSpanTips(element, helper) {
  // Find all spans with data-tip attribute (for simple inline content)
  const tipSpans = element.querySelectorAll('span[data-tip]');
  
  if (tipSpans.length === 0) {
    return;
  }

  tipSpans.forEach((span) => {
    // Skip if already processed
    if (span.classList.contains('inline-tip')) {
      return;
    }
    
    // Get trigger text from data-tip attribute
    const triggerText = span.getAttribute('data-tip');
    
    if (!triggerText) {
      return;
    }

    // Get tooltip content from innerHTML
    const tipContent = span.innerHTML.trim();
    
    if (!tipContent) {
      return;
    }

    // Create tooltip component
    const tipComponent = document.createElement('span');
    tipComponent.className = 'inline-tip';
    
    helper.renderGlimmer(tipComponent, InlineTip, {
      triggerText: triggerText,
      tipContent: tipContent
    });

    // Replace the span with our tooltip
    span.parentNode.replaceChild(tipComponent, span);
  });
}
