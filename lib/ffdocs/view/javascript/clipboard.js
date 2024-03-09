document.addEventListener("DOMContentLoaded", () => {
  if(!navigator.clipboard || !navigator.clipboard.writeText) {
    console.log("clipboard.writeText not available.\nIt is required for the 'Copy' button in code snippets.");
    return;
  }

  function notifyClipboardResult(button, message) {
    let original = button.innerText;
    button.innerText = message;
    button.classList.add("result");
    setTimeout(() => {
      button.innerText = original;
      button.classList.remove("result");
    }, 1500);
  }

  for(const elem of document.querySelectorAll("pre[data-source]")) {
    let button = document.createElement("BUTTON");

    button.classList.add("copy");
    button.append(document.createTextNode("📋"));

    button.addEventListener("click", () => {
      navigator.clipboard.writeText(elem.dataset.source).then(
        () => { notifyClipboardResult(button, "✓"); },
        () => { notifyClipboardResult(button, "✗"); }
      );
    });

    elem.prepend(button);
  }
});
