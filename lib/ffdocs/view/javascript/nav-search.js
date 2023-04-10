document.addEventListener("DOMContentLoaded", () => {
  // Check if this page contains an items tree in <nav>.
  if(document.querySelector("nav .current-version details") === null) {
    return;
  }

  // Add an icon for the search input.
  let search = document.createElement("INPUT");
  search.placeholder = "Search";
  search.accessKey = "s";
  search.classList.add("search");

  // Update visible items when the input is modified.
  let nsi = new NavSearchInput();
  search.addEventListener("input", () => {
    nsi.update(search.value.trim());
  });

  let labelHeader = document.querySelector(".current-version > b");
  labelHeader.parentNode.insertBefore(search, labelHeader);

});

class NavSearchInput {
  constructor() {
    this.nodesState = null;
  }

  update(query) {
    if(query === "") {
      if(this.nodesState !== null) {
        this.restoreNodesState();
      }

      return;
    }

    if(this.nodesState === null) {
      this.saveNodesState();
    }

    let words = query.split(/ +/);
    let visibleNodes = new WeakSet();

    // Hide links that does not contains the words in the input.
    for(const elem of document.querySelectorAll("nav details :is(a, b)")) {
      let link = elem.innerText;
      let visible = words.every(w => link.includes(w));
      elem.style.display = visible ? "" : "none";

      if(visible) {
        let it = elem;
        while(true) {
          it = it.parentNode;
          if(it === null) {
            break
          } else if(it.tagName === "DETAILS") {
            visibleNodes.add(it);
          }
        }
      }
    }

    // Show only <details> nodes with visible items.
    for(const elem of document.querySelectorAll("nav details")) {
      if(visibleNodes.has(elem)) {
        elem.style.display = "";
        elem.open = true;
      } else {
        elem.style.display = "none";
      }
    }
  }

  saveNodesState() {
    let map = new WeakMap();

    for(const elem of document.querySelectorAll("nav details")) {
      map.set(elem, elem.open);
    }

    this.nodesState = map;
  }

  restoreNodesState() {
    if(this.nodesState === null) {
      return;
    }

    let map = this.nodesState;
    for(const elem of document.querySelectorAll("nav details")) {
      elem.open = map.get(elem);
      elem.style.display = "";
    }

    for(const elem of document.querySelectorAll("nav details :is(a, b)")) {
      elem.style.display = "";
    }

    this.nodesState = null;
  }

}
