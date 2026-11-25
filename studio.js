/* Progressive enhancement only: highlights the current section in the ribbon and the current row in the Explorer
   while scrolling. If the row sits in a collapsed group, the group's own row is highlighted instead.
   The page, the links and the collapsible tree all work without this file. */
(function () {
  var links = {};
  document.querySelectorAll('.ribbon a, .explorer a').forEach(function (a) {
    var id = (a.getAttribute('href') || '').slice(1);
    if (id) (links[id] = links[id] || []).push(a);
  });
  var heads = [].slice.call(document.querySelectorAll('[id]')).filter(function (e) { return links[e.id]; });
  if (!heads.length) return;
  var ticking = false;

  function isSection(e) { return e.tagName === 'SECTION' || e.id === 'top'; }
  function inExplorer(a) { return !!a.closest('.explorer'); }
  function inRibbon(a) { return !!a.closest('.ribbon'); }

  function update() {
    ticking = false;
    var row = heads[0], sec = heads[0];
    var atBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 4;
    var picked = atBottom && location.hash ? heads.filter(function (e) { return '#' + e.id === location.hash; })[0] : null;
    if (picked && picked.getBoundingClientRect().top > window.innerHeight - 40) picked = null;
    if (picked) {
      // At the bottom of a short page two sections can be on screen; honour the link the visitor just followed.
      row = picked;
      sec = isSection(picked) ? picked : (heads.filter(function (e) { return isSection(e) && e.contains(picked); })[0] || picked);
    } else if (atBottom) {
      row = heads[heads.length - 1];
      sec = heads.filter(isSection).pop();
    } else {
      heads.forEach(function (e) {
        if (e.getBoundingClientRect().top <= 120) {
          row = e;
          if (isSection(e)) sec = e;
        }
      });
    }
    document.querySelectorAll('[aria-current="location"]').forEach(function (a) { a.removeAttribute('aria-current'); });
    (links[sec.id] || []).filter(inRibbon).forEach(function (a) { a.setAttribute('aria-current', 'location'); });

    var target = (links[row.id] || []).filter(inExplorer)[0];
    if (target && !target.closest('summary')) {
      var group = target.closest('details');
      if (group && !group.open) target = (links[sec.id] || []).filter(inExplorer)[0];
    }
    if (target) {
      target.setAttribute('aria-current', 'location');
      var box = document.querySelector('.explorer');
      if (box) {
        var r = target.getBoundingClientRect(), b = box.getBoundingClientRect();
        if (r.top < b.top + 40 || r.bottom > b.bottom - 8) box.scrollTop += r.top - b.top - b.height / 2;
      }
    }
  }

  function onScroll() {
    if (!ticking) { ticking = true; requestAnimationFrame(update); }
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onScroll);
  document.addEventListener('toggle', onScroll, true); // <details> toggle events do not bubble
  update();
})();
