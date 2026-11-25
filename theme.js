/* Theme choice: Auto (follow the system), Light or Dark. Loaded in <head> without defer so a saved choice does not
   flash. The page works without it: with no JavaScript the system setting applies and the button stays hidden. */
(function () {
  var KEY = 'theme', root = document.documentElement, choice = null;
  try { choice = localStorage.getItem(KEY); } catch (e) {}
  if (choice !== 'light' && choice !== 'dark') choice = null;
  function apply() {
    if (choice) root.setAttribute('data-theme', choice); else root.removeAttribute('data-theme');
  }
  apply();
  document.addEventListener('DOMContentLoaded', function () {
    var btn = document.querySelector('.themebtn');
    if (!btn) return;
    var order = [null, 'light', 'dark'];
    function label() {
      var c = choice || 'auto';
      btn.textContent = 'Theme: ' + c.charAt(0).toUpperCase() + c.slice(1);
    }
    btn.hidden = false;
    label();
    btn.addEventListener('click', function () {
      choice = order[(order.indexOf(choice) + 1) % order.length];
      try { if (choice) localStorage.setItem(KEY, choice); else localStorage.removeItem(KEY); } catch (e) {}
      apply();
      label();
    });
  });
})();
