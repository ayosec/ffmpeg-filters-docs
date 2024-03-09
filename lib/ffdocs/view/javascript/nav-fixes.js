document.addEventListener("DOMContentLoaded", () => {
  let selected = document.querySelector("nav .items b");
  if (selected === null) {
    return;
  }

  // If the items container has a scrollbar, try to put the item
  // of this page at the viewport center.

  let rect = selected.getBoundingClientRect();

  let parent = selected.parentElement;
  let parentRect = parent.getBoundingClientRect();

  let delta = rect.bottom - parentRect.bottom + (parentRect.height - rect.height) / 2;
  if (delta > 0) {
    parent.scrollBy(0, delta);
  }
})
