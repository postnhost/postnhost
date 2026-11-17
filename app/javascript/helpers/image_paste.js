export function imageClipboardContent(clipboard) {
  if (!clipboard) return null

  const html = clipboard.getData('text/html')
  // Prefer rich content over file items: browsers may provide both for the same image.
  const body = new DOMParser().parseFromString(html, 'text/html').body
  if (body.querySelector('img')) return { body }

  const files = Array.from(clipboard.files || []).filter(file => file.type.startsWith('image/'))
  return files.length ? { files } : null
}

export async function insertUploadedImages(editor, { body, files }, upload) {
  let bookmark = editor.state.selection.getBookmark()
  const mapSelection = ({ transaction }) => { bookmark = bookmark.map(transaction.mapping) }
  editor.on('transaction', mapSelection)

  try {
    const images = body ? Array.from(body.querySelectorAll('img')) : files
    // Upload sequentially to bound memory and keep clipboard order.
    let failed = false
    const nodes = []
    for (const image of images) {
      try {
        const source = body ? image.getAttribute('src') : image
        if (!source) throw new Error('Missing image source')
        const url = await upload(source)
        if (body) {
          image.setAttribute('src', url)
          image.removeAttribute('srcset')
          image.removeAttribute('sizes')
        } else {
          nodes.push({ type: 'imageResize', attrs: { src: url } })
        }
      } catch {
        failed = true
        if (body) image.replaceWith(document.createTextNode(image.getAttribute('alt') || ''))
      }
      if (editor.isDestroyed) return
    }

    const selection = bookmark.resolve(editor.state.doc)
    const content = body ? body.innerHTML : nodes
    if (content.length) {
      editor.commands.insertContentAt(
        { from: selection.from, to: selection.to },
        content,
        { updateSelection: editor.state.selection.eq(selection) }
      )
    }
    if (failed) throw new Error('Some pasted images could not be uploaded')
  } finally {
    editor.off('transaction', mapSelection)
  }
}
