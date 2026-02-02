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
  
  // Create the tooltip markup
  // Use HTML comment markers to preserve content through Markdown processing
  const htmlTag = "strong";
  const insertion = `<!--tip:start:${triggerText}-->Tooltip content with **markdown** and <${htmlTag}>HTML</${htmlTag}><!--tip:end-->`;

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

  // Process HTML comment-based tips
  processCommentTips(element, helper);
  
  // Also process legacy span-based tips (for inline content only)
  processSpanTips(element, helper);
  
  element.classList.add("inline-tips-processed");
}

function processCommentTips(element, helper) {
  // Find all HTML comment pairs that mark tooltip boundaries
  const walker = document.createTreeWalker(
    element,
    NodeFilter.SHOW_COMMENT,
    null,
    false
  );
  
  const startComments = [];
  let node;
  
  while (node = walker.nextNode()) {
    if (node.nodeValue.startsWith('tip:start:')) {
      startComments.push(node);
    }
  }
  
  startComments.forEach((startComment) => {
    // Extract trigger text from comment
    const triggerText = startComment.nodeValue.replace('tip:start:', '');
    
    // Find the end comment
    let currentNode = startComment.nextSibling;
    const contentNodes = [];
    let endComment = null;
    
    while (currentNode) {
      if (currentNode.nodeType === Node.COMMENT_NODE && currentNode.nodeValue === 'tip:end') {
        endComment = currentNode;
        break;
      }
      contentNodes.push(currentNode);
      currentNode = currentNode.nextSibling;
    }
    
    if (!endComment || contentNodes.length === 0) {
      return;
    }
    
    // Gather the HTML content between comments
    const tipContent = contentNodes.map(node => {
      if (node.nodeType === Node.ELEMENT_NODE) {
        return node.outerHTML;
      } else if (node.nodeType === Node.TEXT_NODE) {
        return node.textContent;
      }
      return '';
    }).join('').trim();
    
    // Create tooltip component
    const tipComponent = document.createElement('span');
    tipComponent.className = 'inline-tip';
    
    helper.renderGlimmer(tipComponent, InlineTip, {
      triggerText: triggerText,
      tipContent: tipContent
    });
    
    // Insert tooltip before start comment
    startComment.parentNode.insertBefore(tipComponent, startComment);
    
    // Remove all the content nodes and comments
    startComment.parentNode.removeChild(startComment);
    contentNodes.forEach(node => {
      if (node.parentNode) {
        node.parentNode.removeChild(node);
      }
    });
    if (endComment.parentNode) {
      endComment.parentNode.removeChild(endComment);
    }
  });
}

function processSpanTips(element, helper) {
  // Find all spans with data-tip attribute (legacy support for inline content)
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

    // Get tooltip content from innerHTML (between the span tags)
    let tipContent = span.innerHTML.trim();
    
    if (!tipContent) {
      return;
    }
    
    // Clean up the content
    tipContent = tipContent.replace(/^["'\s]+|["'\s]+$/g, '');

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
