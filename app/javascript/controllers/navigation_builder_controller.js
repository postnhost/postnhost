import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "headerList",
    "footerList",
    "treeInput",
    "targetOptions",
    "headerToggle",
    "headerBuilder",
    "footerToggle",
    "footerBuilder",
    "dragHandleIconTemplate",
    "chevronDownIconTemplate"
  ]

  static values = {
    tree: Object,
    locale: String
  }

  connect() {
    this.element.dataset.navigationBuilderReady = "true"
    this.nextId = -1
    this.dragSourcePath = null
    this.dragSourceElement = null
    this.dragOverElement = null
    this.tree = this.normalizeTree(this.hasTreeValue ? this.treeValue : null)
    this.targetOptions = this.parseTargetOptions()
    this.render()
    this.syncBeforeSubmit()
  }

  addHeaderLink() {
    this.tree.header.unshift(this.baseItem("link"))
    this.render()
  }

  addHeaderDropdown() {
    this.tree.header.unshift({ ...this.baseItem("dropdown"), children: [] })
    this.render()
  }

  addFooterColumn() {
    this.tree.footer.unshift({ id: this.genId(), kind: "column", label: "", children: [] })
    this.render()
  }

  addChild(event) {
    const path = event.currentTarget.dataset.path
    const parent = this.itemAt(path)
    if (!parent) return
    parent.children ||= []
    parent.children.unshift(this.baseItem("link"))
    this.render()
  }

  removeItem(event) {
    const path = event.currentTarget.dataset.path
    this.removeAt(path)
    this.render()
  }

  toggleHeaderMode() {
    this.#toggleMode(this.headerToggleTarget, this.headerBuilderTarget)
  }

  toggleFooterMode() {
    this.#toggleMode(this.footerToggleTarget, this.footerBuilderTarget)
  }

  syncBeforeSubmit() {
    this.treeInputTarget.value = JSON.stringify(this.tree)
    this.element.dataset.navigationBuilderTreeValue = this.treeInputTarget.value
  }

  updateField(event) {
    const path = event.currentTarget.dataset.path
    const field = event.currentTarget.dataset.field
    if (!path || !field) return
    const item = this.itemAt(path)
    if (!item) return
    item[field] = event.currentTarget.type === "checkbox" ? event.currentTarget.checked : event.currentTarget.value
    if (field === "target_kind") {
      item.target_id = ""
      item.target_slug = ""
      item.url = ""
      item.nofollow = false
      this.render()
      return
    }
    this.syncBeforeSubmit()
  }

  dragStart(event) {
    event.stopPropagation()
    const path = event.currentTarget.dataset.path
    if (!path) return
    this.dragSourcePath = path
    this.dragSourceElement = event.currentTarget.closest("[data-path]")
    this.clearDropHighlight()
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", path)
  }

  dragOver(event) {
    event.stopPropagation()
    event.preventDefault()
    const target = event.currentTarget
    if (!target || target === this.dragOverElement) return
    this.clearDropHighlight()
    this.dragOverElement = target
    this.dragOverElement.classList.add("border-blue-500", "ring-2", "ring-blue-100")
  }

  drop(event) {
    event.stopPropagation()
    event.preventDefault()
    const fromPath = event.dataTransfer.getData("text/plain")
    const toPath = event.currentTarget.dataset.path
    if (!fromPath || !toPath || fromPath === toPath) {
      this.clearDragVisuals()
      return
    }

    const fromParentPath = fromPath.split(".").slice(0, -1).join(".")
    const toParentPath = toPath.split(".").slice(0, -1).join(".")
    if (fromParentPath !== toParentPath) {
      this.clearDragVisuals()
      return
    }

    const fromIndex = Number(fromPath.split(".").pop())
    const toIndex = Number(toPath.split(".").pop())
    const list = this.listAt(fromParentPath)
    if (!Array.isArray(list) || Number.isNaN(fromIndex) || Number.isNaN(toIndex)) {
      this.clearDragVisuals()
      return
    }

    const moved = list.splice(fromIndex, 1)[0]
    if (!moved) {
      this.clearDragVisuals()
      return
    }

    list.splice(toIndex, 0, moved)
    this.clearDragVisuals()
    this.render()
  }

  dragEnd() {
    this.clearDragVisuals()
  }

  clearDropHighlight() {
    if (!this.dragOverElement) return
    this.dragOverElement.classList.remove("border-blue-500", "ring-2", "ring-blue-100")
    this.dragOverElement = null
  }

  clearDragVisuals() {
    this.clearDropHighlight()
    this.dragSourcePath = null
    this.dragSourceElement = null
  }

  toggleCollapse(event) {
    const path = event.currentTarget.dataset.path
    const item = this.itemAt(path)
    if (!item) return
    item.collapsed = !item.collapsed

    const itemElement = event.currentTarget.closest("div[data-path]")
    if (itemElement) {
      const detailsElement = itemElement.querySelector(":scope > div.border-t")
      if (detailsElement) {
        detailsElement.classList.toggle("hidden", item.collapsed)
      }
    }

    const iconWrapper = event.currentTarget.querySelector("[data-role='collapse-icon']")
    if (iconWrapper) {
      iconWrapper.classList.toggle("rotate-180", !item.collapsed)
    }

    event.currentTarget.setAttribute("aria-label", item.collapsed ? "Expand" : "Collapse")
    this.syncBeforeSubmit()
  }

  render() {
    const headerItems = Array.isArray(this.tree.header) ? this.tree.header : []
    const footerItems = Array.isArray(this.tree.footer) ? this.tree.footer : []

    this.headerListTarget.innerHTML = this.renderList(headerItems, "header")
    this.footerListTarget.innerHTML = this.renderList(footerItems, "footer")
    this.syncBeforeSubmit()
  }

  renderList(items, path) {
    return items.map((item, index) => this.renderItem(item, `${path}.${index}`)).join("")
  }

  renderItem(item, path) {
    const typeLabel = item.kind === "dropdown" ? "Dropdown" : item.kind === "column" ? "Column" : item.target_kind === "text" ? "Text" : "Link"
    const isCollapsed = item.collapsed === true
    const headingLabel = this.displayLabel(item)

    return `<div class="group/item rounded-lg border border-gray-200 bg-white overflow-hidden transition-colors hover:border-gray-300" data-path="${path}" draggable="true" data-action="dragstart->navigation-builder#dragStart dragend->navigation-builder#dragEnd dragover->navigation-builder#dragOver drop->navigation-builder#drop">
      <div class="flex items-center justify-between gap-2 pl-1 pr-2 py-2">
        <div class="flex min-w-0 items-center gap-2">
          <span class="inline-flex items-center justify-center h-8 w-8 rounded text-gray-700 hover:text-gray-900 hover:bg-gray-100 cursor-grab active:cursor-grabbing" title="Drag to reorder" aria-label="Drag to reorder">${this.dragHandleIconMarkup()}</span>
          <button type="button" data-path="${path}" data-action="navigation-builder#toggleCollapse" class="inline-flex items-center justify-center h-7 w-7 rounded text-gray-500 hover:text-gray-700 hover:bg-gray-100 transition-colors cursor-pointer" aria-label="${isCollapsed ? "Expand" : "Collapse"}">${this.collapseChevronIconMarkup(!isCollapsed)}</button>
          <span class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-xs font-medium ${item.kind === "dropdown" ? "border-blue-200 bg-blue-50 text-blue-700" : item.kind === "column" ? "border-emerald-200 bg-emerald-50 text-emerald-700" : "border-gray-300 bg-gray-100 text-gray-700"}">${typeLabel}</span>
          <span class="truncate text-sm font-medium text-gray-900">${this.safe(headingLabel)}</span>
        </div>
        <div class="flex items-center gap-1.5">
          <button type="button" data-path="${path}" data-action="navigation-builder#removeItem" class="inline-flex items-center justify-center h-[26px] w-[26px] rounded text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer" aria-label="Remove">✕</button>
        </div>
      </div>
      <div class="border-t border-gray-200 bg-gray-50 px-3 py-3 ${isCollapsed ? "hidden" : ""}">
      <div class="space-y-3">
        <div class="space-y-1">
          <label class="${this.labelClass()}">Label (${this.localeValue || "locale"})${item.kind === "link" ? '<span class="font-normal text-gray-400"> - Optional</span>' : ""}</label>
          <input data-path="${path}" data-field="label" data-action="input->navigation-builder#updateField" class="${this.inputClass()}" value="${this.safe(item.label || "")}" />
        </div>
        ${item.kind === "link" ? this.renderLinkFields(item, path) : ""}
      </div>
      ${item.kind === "dropdown" || item.kind === "column" ? `<div class="mt-3 border-t border-gray-100 pt-3 space-y-3">
        <div class="flex items-center justify-between">
          <button type="button" data-path="${path}" data-action="navigation-builder#addChild" class="inline-flex items-center px-2.5 py-1.5 rounded-md text-xs border border-dashed border-gray-300 bg-white hover:bg-gray-50 cursor-pointer">+ Add link</button>
        </div>
        ${this.renderList(item.children || [], `${path}.children`)}
      </div>` : ""}
      </div>
    </div>`
  }

  renderLinkFields(item, path) {
    const isExternal = item.target_kind === "external"
    const isText = item.target_kind === "text"
    const options = ["article", "page", "category", "static_page", "external", "text"]
      .map((kind) => `<option value="${kind}" ${item.target_kind === kind ? "selected" : ""}>${this.prettyTargetKind(kind)}</option>`)
      .join("")

    return `<div class="grid grid-cols-1 md:grid-cols-2 gap-3">
      <div class="space-y-1">
        <label class="${this.labelClass()}">Target Type</label>
        <select data-path="${path}" data-field="target_kind" data-action="change->navigation-builder#updateField" class="${this.inputClass()}">${options}</select>
      </div>
      ${this.renderTargetInput(item, path)}
      <div class="${isExternal && !isText ? "" : "hidden"}">
        <label class="inline-flex items-center gap-2 text-xs text-gray-700 mt-1 cursor-pointer"><input type="checkbox" data-path="${path}" data-field="nofollow" data-action="change->navigation-builder#updateField" ${item.nofollow ? "checked" : ""} class="rounded border-gray-300" />Add nofollow</label>
      </div>
    </div>`
  }

  renderTargetInput(item, path) {
    if (item.target_kind === "text") {
      return ""
    }

    if (item.target_kind === "external") {
      return `<div class="space-y-1"><label class="${this.labelClass()}">URL</label><input data-path="${path}" data-field="url" data-action="input->navigation-builder#updateField" value="${this.safe(item.url || "")}" class="${this.inputClass()}" placeholder="https://example.com" /></div>`
    }

    const optionValues = this.targetOptions[item.target_kind] || []
    const field = item.target_kind === "static_page" ? "target_slug" : "target_id"
    const selected = String(item[field] || "")
    const selectOptions = [`<option value="">Select</option>`]
      .concat(optionValues.map(([label, value]) => `<option value="${this.safe(String(value))}" ${selected === String(value) ? "selected" : ""}>${this.safe(label)}</option>`))
      .join("")

    return `<div class="space-y-1"><label class="${this.labelClass()}">Target</label><select data-path="${path}" data-field="${field}" data-action="change->navigation-builder#updateField" class="${this.inputClass()}">${selectOptions}</select></div>`
  }

  baseItem(kind) {
    return {
      id: this.genId(),
      kind,
      label: "",
      target_kind: kind === "link" ? "page" : "",
      target_id: "",
      target_slug: "",
      url: "",
      nofollow: false,
      children: []
    }
  }

  genId() {
    this.nextId -= 1
    return this.nextId
  }

  itemAt(path) {
    if (!path) return null
    const parts = path.split(".")
    let node = this.tree
    let i = 0
    while (i < parts.length) {
      const key = parts[i]
      if (node == null) return null
      if (key === "header" || key === "footer" || key === "children") {
        node = node[key]
      } else {
        if (!Array.isArray(node)) return null
        node = node[Number(key)]
      }
      i += 1
    }
    return node || null
  }

  listAt(path) {
    if (!path) return null
    const parts = path.split(".")
    let node = this.tree
    let i = 0
    while (i < parts.length) {
      const key = parts[i]
      if (node == null) return null
      if (key === "header" || key === "footer" || key === "children") {
        node = node[key]
      } else {
        if (!Array.isArray(node)) return null
        node = node[Number(key)]
      }
      i += 1
    }
    return Array.isArray(node) ? node : null
  }

  removeAt(path) {
    if (!path) return
    const parts = path.split(".")
    const index = Number(parts.pop())
    const list = this.listAt(parts.join("."))
    if (!Array.isArray(list) || Number.isNaN(index)) return
    list.splice(index, 1)
  }

  normalizeTree(rawTree) {
    const tree = rawTree && typeof rawTree === "object" ? rawTree : {}
    return {
      header: this.normalizeItems(tree.header),
      footer: this.normalizeItems(tree.footer)
    }
  }

  normalizeItems(rawItems) {
    if (!Array.isArray(rawItems)) return []
    return rawItems
      .map((rawItem) => this.normalizeItem(rawItem))
      .filter((item) => item)
  }

  normalizeItem(rawItem) {
    if (!rawItem || typeof rawItem !== "object") return null

    const kind = ["link", "dropdown", "column"].includes(rawItem.kind) ? rawItem.kind : "link"
    const targetKind = ["article", "page", "category", "static_page", "external", "text"].includes(rawItem.target_kind) ?
      rawItem.target_kind :
      (kind === "link" ? "page" : "")

    return {
      id: rawItem.id ?? this.genId(),
      kind,
      label: String(rawItem.label || ""),
      target_kind: targetKind,
      target_id: rawItem.target_id || "",
      target_slug: rawItem.target_slug || "",
      url: rawItem.url || "",
      nofollow: rawItem.nofollow === true,
      collapsed: rawItem.collapsed === true || Number(rawItem.id) > 0,
      children: this.normalizeItems(rawItem.children)
    }
  }

  parseTargetOptions() {
    try {
      return JSON.parse(this.targetOptionsTarget.value || "{}")
    } catch (error) {
      return {}
    }
  }

  safe(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }

  labelClass() {
    return "text-xs font-medium text-gray-700"
  }

  inputClass() {
    return "w-full px-3 py-2 border border-gray-200 rounded-md text-sm bg-white"
  }

  prettyTargetKind(kind) {
    switch (kind) {
      case "article":
        return "Article"
      case "page":
        return "Page"
      case "category":
        return "Category"
      case "static_page":
        return "Static Page"
      case "external":
        return "External Link"
      case "text":
        return "Text"
      default:
        return kind
    }
  }

  displayLabel(item) {
    const custom = String(item.label || "").trim()
    if (custom) return custom

    const fallback = this.fallbackTargetLabel(item)
    if (fallback) return fallback

    return "Untitled"
  }

  #toggleMode(toggle, builder) {
    builder.classList.toggle("hidden", toggle.checked)
  }

  fallbackTargetLabel(item) {
    if (!item || item.kind !== "link") return ""
    if (item.target_kind === "text") return ""
    if (item.target_kind === "external") return String(item.url || "").trim()

    if (item.target_kind === "static_page") {
      const staticOptions = this.targetOptions.static_page || []
      const staticOption = staticOptions.find(([, value]) => String(value) === String(item.target_slug || ""))
      return staticOption ? String(staticOption[0]) : ""
    }

    const options = this.targetOptions[item.target_kind] || []
    const option = options.find(([, value]) => String(value) === String(item.target_id || ""))
    return option ? String(option[0]) : ""
  }

  dragHandleIconMarkup() {
    return this.hasDragHandleIconTemplateTarget ? this.dragHandleIconTemplateTarget.innerHTML : ""
  }

  collapseChevronIconMarkup(isExpanded) {
    const rotationClass = isExpanded ? " rotate-180" : ""
    const iconMarkup = this.hasChevronDownIconTemplateTarget ? this.chevronDownIconTemplateTarget.innerHTML : ""
    return `<span data-role="collapse-icon" class="inline-flex transition-transform duration-200${rotationClass}">${iconMarkup}</span>`
  }
}
