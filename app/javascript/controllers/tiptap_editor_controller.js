import { Controller } from "@hotwired/stimulus"
import { Editor, Extension, textInputRule } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import HorizontalRule from '@tiptap/extension-horizontal-rule'
import TextAlign from '@tiptap/extension-text-align'
import Superscript from '@tiptap/extension-superscript'
import Subscript from '@tiptap/extension-subscript'
import Underline from '@tiptap/extension-underline'
import Highlight from '@tiptap/extension-highlight'
import Link from '@tiptap/extension-link'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import ImageResizeBase from 'tiptap-extension-resize-image'

// Extend ImageResize to preserve alt attribute and output wrapper divs for alignment
const ImageResize = ImageResizeBase.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      alt: {
        default: null,
        parseHTML: element => element.getAttribute('alt'),
        renderHTML: attributes => {
          if (!attributes.alt) {
            return {}
          }
          return { alt: attributes.alt }
        },
      },
    }
  },

  renderHTML({ HTMLAttributes, node }) {
    const { containerStyle, wrapperStyle, ...imgAttrs } = HTMLAttributes

    // If no alignment styles, just render the img
    if (!containerStyle && !wrapperStyle) {
      return ['img', imgAttrs]
    }

    // Render with wrapper divs for alignment (flex container + positioned inner div)
    return [
      'div',
      { style: containerStyle || 'display: flex;', class: 'image-container' },
      [
        'div',
        { style: wrapperStyle || 'position: relative;', class: 'image-wrapper' },
        ['img', imgAttrs]
      ]
    ]
  },

  parseHTML() {
    return [
      {
        // Parse wrapper structure: div.image-container > div.image-wrapper > img
        tag: 'div.image-container',
        getAttrs: node => {
          const wrapper = node.querySelector('.image-wrapper')
          const img = wrapper?.querySelector('img') || node.querySelector('img')
          if (!img) return false

          return {
            src: img.getAttribute('src'),
            alt: img.getAttribute('alt'),
            width: img.getAttribute('width'),
            containerStyle: node.getAttribute('style'),
            wrapperStyle: wrapper?.getAttribute('style'),
          }
        },
      },
      {
        // Also parse plain img tags
        tag: 'img[src]',
        getAttrs: node => ({
          src: node.getAttribute('src'),
          alt: node.getAttribute('alt'),
          width: node.getAttribute('width'),
        }),
      },
    ]
  },
})
import { Table } from '@tiptap/extension-table'
import { TableRow } from '@tiptap/extension-table-row'
import { TableHeader } from '@tiptap/extension-table-header'
import { TableCell } from '@tiptap/extension-table-cell'
import Youtube from '@tiptap/extension-youtube'
import { codeLowlight } from '../helpers/code_highlighting'
import { applyClasses, removeClasses, EDITOR_STATES } from "../helpers/style_helpers"

const SmartDashes = Extension.create({
  name: 'smartDashes',
  addInputRules() {
    return [
      textInputRule({ find: /–-$/, replace: '—' }),
      textInputRule({ find: /---$/, replace: '—' }),
      textInputRule({ find: /--$/, replace: '–' }),
    ]
  },
})

export default class extends Controller {
  static targets = ["editor", "content", "linkDropdown", "linkInput", "altDropdown", "altInput", "youtubeDropdown", "youtubeInput", "codeLanguage"]
  static values = {
    content: String,
    resourceType: String,
    resourceId: String,
    mountPath: { type: String, default: '' }
  }

  connect() {
    this.initializeEditor()
    window.addEventListener('resize', this.#positionCodeLanguageControl)
    this.setupPasteHandler()
    this.setupDragAndDropHandler()
  }

  disconnect() {
    window.removeEventListener('resize', this.#positionCodeLanguageControl)
    if (this.editor) {
      this.editor.destroy()
    }
  }

  initializeEditor() {
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [
        StarterKit.configure({
          heading: {
            levels: [1, 2, 3]
          },
          horizontalRule: false,
          codeBlock: false,
        }),
        CodeBlockLowlight.configure({
          lowlight: codeLowlight,
          defaultLanguage: 'plaintext',
          enableTabIndentation: true,
          tabSize: 2,
        }),
        HorizontalRule,
        SmartDashes,
        TextAlign.configure({
          types: ['heading', 'paragraph'],
        }),

        Superscript,
        Subscript,
        Underline,
        Highlight.configure({
          multicolor: true,
          HTMLAttributes: {
            class: 'highlight',
          },
        }),
        Link.configure({
          openOnClick: false,
          HTMLAttributes: {
            target: '_blank',
            rel: 'noopener noreferrer nofollow',
          },
        }),
        TaskList,
        TaskItem.configure({
          nested: true,
        }),
        ImageResize.configure({
          inline: false,
          allowBase64: false,
        }),
        Table.configure({
          resizable: true,
          HTMLAttributes: {
            class: null,
          },
        }),
        TableRow.configure({
          HTMLAttributes: {
            class: null,
          },
        }),
        TableHeader.configure({
          HTMLAttributes: {
            class: null,
          },
        }),
        TableCell.configure({
          HTMLAttributes: {
            class: null,
          },
        }),
        Youtube.configure({
          controls: true,
          nocookie: true,
          modestBranding: true,
          width: 0,
          height: 0,
          HTMLAttributes: {
            class: 'youtube-embed',
          },
        }),
      ],
      content: this.contentValue || '',
      editorProps: {
        attributes: {
          class: 'prose max-w-none focus:outline-none min-h-[400px] p-4',
        },
      },
      onUpdate: ({ editor }) => {
        this.updateHiddenField(editor.getHTML())
        // Dispatch event for auto-save
        document.dispatchEvent(new CustomEvent('tiptap:content-changed'))
      },
    })

    // Set initial content in hidden field
    this.updateHiddenField(this.editor.getHTML())

    // Focus the editor when loaded
    this.editor.commands.focus()

    // Setup toolbar buttons
    this.setupToolbarButtons()
  }

  updateHiddenField(content) {
    if (this.hasContentTarget) {
      this.contentTarget.value = content
    }
  }

  setupToolbarButtons() {
    // Bold
    this.setupButton('[data-action="bold"]', () => this.editor.chain().focus().toggleBold().run(), () => this.editor.isActive('bold'))

    // Italic
    this.setupButton('[data-action="italic"]', () => this.editor.chain().focus().toggleItalic().run(), () => this.editor.isActive('italic'))

    // Strike
    this.setupButton('[data-action="strike"]', () => this.editor.chain().focus().toggleStrike().run(), () => this.editor.isActive('strike'))

    // Code
    this.setupButton('[data-action="code"]', () => this.editor.chain().focus().toggleCode().run(), () => this.editor.isActive('code'))

    // Underline
    this.setupButton('[data-action="underline"]', () => this.editor.chain().focus().toggleUnderline().run(), () => this.editor.isActive('underline'))

    // Superscript
    this.setupButton('[data-action="superscript"]', () => this.editor.chain().focus().toggleSuperscript().run(), () => this.editor.isActive('superscript'))

    // Subscript
    this.setupButton('[data-action="subscript"]', () => this.editor.chain().focus().toggleSubscript().run(), () => this.editor.isActive('subscript'))

    // Highlight
    this.setupButton('[data-action="highlight"]', () => this.editor.chain().focus().toggleHighlight().run(), () => this.editor.isActive('highlight'))

    // Headings
    this.setupButton('[data-action="heading-1"]', () => this.editor.chain().focus().toggleHeading({ level: 1 }).run(), () => this.editor.isActive('heading', { level: 1 }))
    this.setupButton('[data-action="heading-2"]', () => this.editor.chain().focus().toggleHeading({ level: 2 }).run(), () => this.editor.isActive('heading', { level: 2 }))
    this.setupButton('[data-action="heading-3"]', () => this.editor.chain().focus().toggleHeading({ level: 3 }).run(), () => this.editor.isActive('heading', { level: 3 }))

    // Lists
    this.setupButton('[data-action="bullet-list"]', () => this.editor.chain().focus().toggleBulletList().run(), () => this.editor.isActive('bulletList'))
    this.setupButton('[data-action="ordered-list"]', () => this.editor.chain().focus().toggleOrderedList().run(), () => this.editor.isActive('orderedList'))
    this.setupButton('[data-action="task-list"]', () => this.editor.chain().focus().toggleTaskList().run(), () => this.editor.isActive('taskList'))

    // Blockquote
    this.setupButton('[data-action="blockquote"]', () => this.editor.chain().focus().toggleBlockquote().run(), () => this.editor.isActive('blockquote'))

    // Code block
    this.setupButton('[data-action="code-block"]', () => this.editor.chain().focus().toggleCodeBlock().run(), () => this.editor.isActive('codeBlock'))

    // Horizontal rule
    this.setupButton('[data-action="horizontal-rule"]', () => this.editor.chain().focus().setHorizontalRule().run())

    // Text align
    this.setupButton('[data-action="align-left"]', () => this.editor.chain().focus().setTextAlign('left').run(), () => this.editor.isActive({ textAlign: 'left' }))
    this.setupButton('[data-action="align-center"]', () => this.editor.chain().focus().setTextAlign('center').run(), () => this.editor.isActive({ textAlign: 'center' }))
    this.setupButton('[data-action="align-right"]', () => this.editor.chain().focus().setTextAlign('right').run(), () => this.editor.isActive({ textAlign: 'right' }))
    this.setupButton('[data-action="align-justify"]', () => this.editor.chain().focus().setTextAlign('justify').run(), () => this.editor.isActive({ textAlign: 'justify' }))

    // Link
    this.setupButton('[data-action="link"]', () => this.showLinkDropdown(), () => this.editor.isActive('link'))

    // Image
    this.setupButton('[data-action="image"]', () => this.showImageUpload())

    // Undo/Redo
    this.setupButton('[data-action="undo"]', () => this.editor.chain().focus().undo().run(), null, () => this.editor.can().undo())
    this.setupButton('[data-action="redo"]', () => this.editor.chain().focus().redo().run(), null, () => this.editor.can().redo())

    // Table button (for highlighting when inside table)
    this.setupButton('[data-action="click->dropdown#toggle table"]', null, () => this.editor.isActive('table'))

    // Table actions
    this.setupButton('[data-action="tiptap-editor#insertTable"]', () => this.insertTable())
    this.setupButton('[data-action="tiptap-editor#deleteTable"]', () => this.deleteTable())
    this.setupButton('[data-action="tiptap-editor#addColumnAfter"]', () => this.addColumnAfter())
    this.setupButton('[data-action="tiptap-editor#deleteColumn"]', () => this.deleteColumn())
    this.setupButton('[data-action="tiptap-editor#addRowAfter"]', () => this.addRowAfter())
    this.setupButton('[data-action="tiptap-editor#deleteRow"]', () => this.deleteRow())

    // YouTube
    this.setupButton('[data-action="youtube"]', () => this.showYoutubeDropdown(), () => this.editor.isActive('youtube'))

    // Update button states on selection change
    this.editor.on('selectionUpdate', () => {
      this.updateButtonStates()
    })

    this.editor.on('transaction', () => {
      this.updateButtonStates()
    })

    // Handle clicks on links in the editor
    this.editorTarget.addEventListener('click', (event) => {
      const linkElement = event.target.closest('a')
      if (linkElement) {
        event.preventDefault()
        event.stopImmediatePropagation()

        // Set cursor position to the link
        const pos = this.editor.view.posAtDOM(linkElement, 0)
        this.editor.commands.setTextSelection(pos)

        this.showLinkDropdown()
        return false
      }
    }, true)

    // Handle clicks on images in the editor - delegate to resize plugin, then show alt editor
    this.editorTarget.addEventListener('click', (event) => {
      const imageElement = event.target.closest('img')
      if (imageElement) {
        // Don't prevent default - let resize plugin handle it first
        // Just schedule showing the alt editor after resize controls appear
        setTimeout(() => {
          this.showAltEditor()
        }, 50)
      }
    })

    // Hide alt editor when starting to resize image
    this.editorTarget.addEventListener('mousedown', (event) => {
      const isResizeHandle = event.target.closest('.ProseMirror-widget') ||
        event.target.style?.cursor?.includes('resize')
      if (isResizeHandle && this.altDropdownTarget && !this.altDropdownTarget.classList.contains('hidden')) {
        this.hideAltEditor()
      }
    })

    this.updateButtonStates()
  }

  setupButton(selector, action, isActiveCheck = null, isEnabledCheck = null) {
    const button = this.element.querySelector(selector)
    if (button) {
      button.addEventListener('click', (e) => {
        e.preventDefault()
        action()
      })

      // Store references for state updates
      if (!this.buttons) this.buttons = []
      this.buttons.push({
        element: button,
        isActiveCheck,
        isEnabledCheck
      })
    }
  }

  showLinkDropdown() {
    const linkButton = this.element.querySelector('[data-action="link"]')
    const rect = linkButton.getBoundingClientRect()
    const editorRect = this.element.getBoundingClientRect()

    // Position dropdown below the link button
    this.linkDropdownTarget.style.left = `${rect.left - editorRect.left}px`
    this.linkDropdownTarget.style.top = `${rect.bottom - editorRect.top + 5}px`

    // Get current link URL if exists
    const currentUrl = this.editor.getAttributes('link').href || ''
    this.linkInputTarget.value = currentUrl

    // Show dropdown
    this.linkDropdownTarget.classList.remove('hidden')
    this.linkInputTarget.focus()
    this.linkInputTarget.select()

    // Add click outside listener to close dropdown
    this.handleClickOutside = (e) => {
      if (!this.linkDropdownTarget.contains(e.target) && !linkButton.contains(e.target)) {
        this.hideLinkDropdown()
      }
    }
    document.addEventListener('click', this.handleClickOutside)

    // Add escape key listener
    this.handleEscapeKey = (e) => {
      if (e.key === 'Escape') {
        this.hideLinkDropdown()
      }
    }
    document.addEventListener('keydown', this.handleEscapeKey)
  }

  hideLinkDropdown() {
    this.linkDropdownTarget.classList.add('hidden')
    // Disable validation when hidden to prevent form submission issues
    this.linkInputTarget.removeAttribute('required')
    this.linkInputTarget.value = ''
    document.removeEventListener('click', this.handleClickOutside)
    document.removeEventListener('keydown', this.handleEscapeKey)
  }

  applyLink() {
    const url = this.linkInputTarget.value.trim()

    if (url && url !== 'https://') {
      this.editor.chain().focus().setLink({ href: url }).run()
    } else {
      this.editor.chain().focus().unsetLink().run()
    }

    this.hideLinkDropdown()
  }

  handleLinkInputKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.applyLink()
    }
  }

  removeLink() { this.editor.chain().focus().unsetLink().run(); this.hideLinkDropdown() }

  showAltEditor() {
    // Get the current image node position
    const { state } = this.editor
    const { selection } = state

    // Find the image node - search in a wider range
    let imageNode = null
    let imagePos = null

    // Try to find image node at or near selection
    state.doc.descendants((node, pos) => {
      if (node.type.name === 'imageResize') {
        const nodeStart = pos
        const nodeEnd = pos + node.nodeSize

        // Check if selection is within or near this image node
        if (selection.from >= nodeStart && selection.from <= nodeEnd) {
          imageNode = node
          imagePos = pos
          return false
        }
      }
    })

    if (!imageNode) return

    // Store the image position and original alt text for later use
    this.currentImagePos = imagePos
    this.originalAltText = imageNode.attrs.alt || ''

    // Find the DOM element for the image
    const imageElement = this.editorTarget.querySelector(`img[src="${imageNode.attrs.src}"]`)
    if (!imageElement) return

    // Get the wrapper div (parent of the img)
    const wrapper = imageElement.closest('div[style*="width"]')
    if (!wrapper) return

    const rect = wrapper.getBoundingClientRect()
    const editorRect = this.element.getBoundingClientRect()

    // Position alt dropdown below the image
    this.altDropdownTarget.style.left = `${rect.left - editorRect.left}px`
    this.altDropdownTarget.style.top = `${rect.bottom - editorRect.top + 5}px`
    this.altDropdownTarget.style.width = `${rect.width}px`

    // Set current alt text
    this.altInputTarget.value = this.originalAltText

    // Show dropdown but don't focus the input - let user keep focus on image
    this.altDropdownTarget.classList.remove('hidden')

    // Add click outside listener to close dropdown
    this.handleAltClickOutside = (e) => {
      if (!this.altDropdownTarget.contains(e.target) && !wrapper.contains(e.target)) {
        this.hideAltEditor()
      }
    }
    setTimeout(() => {
      document.addEventListener('click', this.handleAltClickOutside)
    }, 100)
  }

  hideAltEditor() {
    this.altDropdownTarget.classList.add('hidden')
    this.altInputTarget.value = ''
    this.currentImagePos = null
    this.originalAltText = null
    document.removeEventListener('click', this.handleAltClickOutside)
  }

  applyAlt() {
    if (this.currentImagePos === null) return

    const alt = this.altInputTarget.value.trim()
    const { state } = this.editor
    const node = state.doc.nodeAt(this.currentImagePos)

    // Only apply if node exists and alt text actually changed
    if (node && node.type.name === 'imageResize' && alt !== this.originalAltText) {
      // Use native TipTap setImage command to update alt text
      this.editor.chain()
        .focus()
        .setNodeSelection(this.currentImagePos)
        .setImage({
          src: node.attrs.src,
          alt: alt || null,
          width: node.attrs.width,
          containerStyle: node.attrs.containerStyle,
          wrapperStyle: node.attrs.wrapperStyle
        })
        .run()
    }

    this.hideAltEditor()
  }

  handleAltInputChange() {
    // Trigger autosave while typing in alt field
    document.dispatchEvent(new CustomEvent('tiptap:content-changed'))
  }

  handleAltInputKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.applyAlt()
    }
  }

  showYoutubeDropdown() {
    const youtubeButton = this.element.querySelector('[data-action="youtube"]')
    const rect = youtubeButton.getBoundingClientRect()
    const editorRect = this.element.getBoundingClientRect()

    // Position dropdown below the youtube button
    this.youtubeDropdownTarget.style.left = `${rect.left - editorRect.left}px`
    this.youtubeDropdownTarget.style.top = `${rect.bottom - editorRect.top + 5}px`

    // Clear previous value
    this.youtubeInputTarget.value = ''

    // Show dropdown
    this.youtubeDropdownTarget.classList.remove('hidden')
    this.youtubeInputTarget.focus()

    // Add click outside listener to close dropdown
    this.handleYoutubeClickOutside = (e) => {
      if (!this.youtubeDropdownTarget.contains(e.target) && !youtubeButton.contains(e.target)) {
        this.hideYoutubeDropdown()
      }
    }
    document.addEventListener('click', this.handleYoutubeClickOutside)

    // Add escape key listener
    this.handleYoutubeEscapeKey = (e) => {
      if (e.key === 'Escape') {
        this.hideYoutubeDropdown()
      }
    }
    document.addEventListener('keydown', this.handleYoutubeEscapeKey)
  }

  hideYoutubeDropdown() {
    this.youtubeDropdownTarget.classList.add('hidden')
    this.youtubeInputTarget.value = ''
    document.removeEventListener('click', this.handleYoutubeClickOutside)
    document.removeEventListener('keydown', this.handleYoutubeEscapeKey)
  }

  applyYoutube() {
    const url = this.youtubeInputTarget.value.trim()

    if (url) {
      this.editor.chain().focus().setYoutubeVideo({ src: url }).run()
    }

    this.hideYoutubeDropdown()
  }

  handleYoutubeInputKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.applyYoutube()
    }
  }

  changeCodeLanguage(event) {
    if (!this.editor.isActive('codeBlock')) return

    this.editor.chain().focus().updateAttributes('codeBlock', { language: event.currentTarget.value }).run()
  }

  updateButtonStates() {
    if (!this.buttons) return

    this.buttons.forEach(({ element, isActiveCheck, isEnabledCheck }) => {
      // Update active state
      if (isActiveCheck) {
        if (isActiveCheck()) {
          applyClasses(element, EDITOR_STATES.active)
          removeClasses(element, EDITOR_STATES.inactive)
        } else {
          removeClasses(element, EDITOR_STATES.active)
          applyClasses(element, EDITOR_STATES.inactive)
        }
      }

      // Update enabled state
      if (isEnabledCheck) {
        if (isEnabledCheck()) {
          element.disabled = false
          element.classList.remove('opacity-50', 'cursor-not-allowed')
        } else {
          element.disabled = true
          element.classList.add('opacity-50', 'cursor-not-allowed')
        }
      }
    })

    if (this.hasCodeLanguageTarget) {
      const codeBlockActive = this.editor.isActive('codeBlock')
      this.codeLanguageTarget.classList.toggle('hidden', !codeBlockActive)

      if (codeBlockActive) {
        this.codeLanguageTarget.value = this.editor.getAttributes('codeBlock').language || 'plaintext'
        this.#positionCodeLanguageControl()
      }
    }
  }

  #positionCodeLanguageControl = () => {
    if (!this.hasCodeLanguageTarget || !this.editor?.isActive('codeBlock')) return

    const codeBlock = this.#activeCodeBlockElement
    if (!codeBlock) return

    const editorContainer = this.element.getBoundingClientRect()
    const codeBlockBounds = codeBlock.getBoundingClientRect()
    this.codeLanguageTarget.style.top = `${codeBlockBounds.top - editorContainer.top + 8}px`
    this.codeLanguageTarget.style.right = `${editorContainer.right - codeBlockBounds.right + 8}px`
  }

  get #activeCodeBlockElement() {
    const { $from } = this.editor.state.selection

    for (let depth = $from.depth; depth > 0; depth -= 1) {
      if ($from.node(depth).type.name !== 'codeBlock') continue

      return this.editor.view.nodeDOM($from.before(depth))
    }

    return null
  }

  showImageUpload() {
    // Create a hidden file input
    const input = document.createElement('input')
    input.type = 'file'
    input.accept = 'image/*'
    input.style.display = 'none'

    input.addEventListener('change', (event) => {
      const file = event.target.files[0]
      if (file) {
        this.uploadImage(file)
      }
    })

    // Trigger file selection
    input.click()
  }

  uploadImage(file) {
    this.dispatch('upload-start', { bubbles: true })

    const formData = new FormData()
    formData.append('file', file)

    const mountPath = this.mountPathValue === '/' ? '' : this.mountPathValue.replace(/\/$/, '')
    const uploadUrl = this.resourceTypeValue === 'page'
      ? `${mountPath}/pages/${this.resourceIdValue}/images`
      : `${mountPath}/articles/${this.resourceIdValue}/images`

    fetch(uploadUrl, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
      }
    })
      .then(response => response.json())
      .then(data => {
        if (data.url) {
          // Insert image at current cursor position
          this.editor.chain().focus().setImage({ src: data.url }).run()
          this.dispatch('upload-complete', { bubbles: true })
        } else {
          this.dispatch('upload-failed', { bubbles: true })
        }
      })
      .catch(error => {
        console.error('Upload error:', error)
        this.dispatch('upload-failed', { bubbles: true })
      })
  }

  setupPasteHandler() {
    this.editorTarget.addEventListener('paste', (event) => {
      const items = event.clipboardData?.items
      if (!items) return

      for (let i = 0; i < items.length; i++) {
        const item = items[i]

        if (item.type.indexOf('image') !== -1) {
          event.preventDefault()
          const file = item.getAsFile()
          if (file) {
            this.uploadImage(file)
          }
          break
        }
      }
    })
  }

  setupDragAndDropHandler() {
    // Prevent default drag behaviors on the entire editor element
    ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      this.editorTarget.addEventListener(eventName, (e) => {
        e.preventDefault()
        e.stopPropagation()
      })
    })

    // Add visual feedback for drag over
    this.editorTarget.addEventListener('dragenter', (e) => {
      applyClasses(this.editorTarget, EDITOR_STATES.dragOver)
    })

    this.editorTarget.addEventListener('dragleave', (e) => {
      // Only remove styling if we're leaving the editor entirely
      if (!this.editorTarget.contains(e.relatedTarget)) {
        removeClasses(this.editorTarget, EDITOR_STATES.dragOver)
      }
    })

    this.editorTarget.addEventListener('drop', (e) => {
      // Remove visual feedback
      removeClasses(this.editorTarget, EDITOR_STATES.dragOver)

      const files = e.dataTransfer.files
      if (files.length > 0) {
        // Handle multiple files
        Array.from(files).forEach(file => {
          if (file.type.startsWith('image/')) {
            this.uploadImage(file)
          }
        })
      }
    })
  }

  // Table methods
  insertTable() {
    // Don't insert table if already inside a table
    if (this.editor.isActive('table')) {
      return
    }
    this.editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
  }

  deleteTable() {
    this.editor.chain().focus().deleteTable().run()
  }

  addColumnAfter() {
    this.editor.chain().focus().addColumnAfter().run()
  }

  deleteColumn() {
    this.editor.chain().focus().deleteColumn().run()
  }

  addRowAfter() {
    this.editor.chain().focus().addRowAfter().run()
  }

  deleteRow() {
    this.editor.chain().focus().deleteRow().run()
  }
}
