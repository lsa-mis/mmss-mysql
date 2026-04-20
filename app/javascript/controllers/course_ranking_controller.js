import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.draggedItem = null
    this.onDragStart = this.onDragStart.bind(this)
    this.onDragEnd = this.onDragEnd.bind(this)
    this.onDragOver = this.onDragOver.bind(this)
    this.onDrop = this.onDrop.bind(this)

    this.listTargets.forEach((list) => {
      list.addEventListener("dragover", this.onDragOver)
      list.addEventListener("drop", this.onDrop)
      this.itemsFor(list).forEach((item) => {
        item.addEventListener("dragstart", this.onDragStart)
        item.addEventListener("dragend", this.onDragEnd)
      })
    })
  }

  disconnect() {
    this.listTargets.forEach((list) => {
      list.removeEventListener("dragover", this.onDragOver)
      list.removeEventListener("drop", this.onDrop)
      this.itemsFor(list).forEach((item) => {
        item.removeEventListener("dragstart", this.onDragStart)
        item.removeEventListener("dragend", this.onDragEnd)
      })
    })
  }

  moveUp(event) {
    const item = event.currentTarget.closest("[data-item]")
    if (!item) return
    const prev = item.previousElementSibling
    if (!prev) return
    item.parentNode.insertBefore(item, prev)
    this.renumber(item.parentNode)
  }

  moveDown(event) {
    const item = event.currentTarget.closest("[data-item]")
    if (!item) return
    const next = item.nextElementSibling
    if (!next) return
    item.parentNode.insertBefore(next, item)
    this.renumber(item.parentNode)
  }

  onDragStart(event) {
    this.draggedItem = event.currentTarget
    this.draggedItem.classList.add("course-ranking-item--dragging")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "")
  }

  onDragEnd() {
    if (!this.draggedItem) return
    this.draggedItem.classList.remove("course-ranking-item--dragging")
    const list = this.draggedItem.parentNode
    this.renumber(list)
    this.draggedItem = null
  }

  onDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  onDrop(event) {
    event.preventDefault()
    if (!this.draggedItem) return

    const list = event.currentTarget
    const draggableElements = [...list.querySelectorAll("[data-item]")]
    const afterElement = draggableElements.reduce((closest, child) => {
      if (child === this.draggedItem) return closest
      const box = child.getBoundingClientRect()
      const offset = event.clientY - box.top - box.height / 2
      if (offset < 0 && offset > closest.offset) {
        return { offset, element: child }
      }
      return closest
    }, { offset: Number.NEGATIVE_INFINITY, element: undefined }).element

    if (afterElement == null) list.appendChild(this.draggedItem)
    else list.insertBefore(this.draggedItem, afterElement)

    this.renumber(list)
  }

  itemsFor(list) {
    return [...list.querySelectorAll("[data-item]")]
  }

  renumber(list) {
    if (!list) return
    const selects = [...list.querySelectorAll("select[name^='rankings']")]
    selects.forEach((select, index) => {
      const value = String(index + 1)
      if ([...select.options].some((opt) => opt.value === value)) select.value = value
    })
  }
}
