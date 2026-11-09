// Parse and rank search preferences; retain the latest choice per menu/query, up to 256 entries.

// One recent choice per menu and search phrase, newest first.
function normalizeQuery(query) {
  return String(query || "").trim().toLowerCase().replace(/\s+/g, " ")
}

function parse(raw) {
  if (!raw || raw.length > 1048576) return []
  try {
    var data = JSON.parse(raw)
    if (data.version !== 1 || !Array.isArray(data.selections)) return []
    return data.selections.filter(function(entry) {
      return entry && typeof entry.menu === "string" && entry.menu.length <= 512
        && typeof entry.query === "string" && entry.query.length > 0 && entry.query.length <= 256
        && typeof entry.itemId === "string" && entry.itemId.length > 0 && entry.itemId.length <= 512
    }).slice(0, 256)
  } catch (e) {
    return []
  }
}

function preferred(history, menu, query) {
  var normalized = normalizeQuery(query)
  for (var i = 0; i < history.length; i++) {
    if (history[i].menu === menu && history[i].query === normalized) return history[i].itemId
  }
  return ""
}

function remember(history, menu, query, itemId) {
  var normalized = normalizeQuery(query)
  if (!normalized || normalized.length > 256) return history
  var remaining = history.filter(function(entry) {
    return entry.menu !== menu || entry.query !== normalized
  })
  return [{ menu: menu, query: normalized, itemId: itemId }].concat(remaining).slice(0, 256)
}

function promote(rows, itemId) {
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].itemId === itemId) {
      var chosen = rows.splice(i, 1)[0]
      chosen.section = ""
      rows.unshift(chosen)
      break
    }
  }
  return rows
}
