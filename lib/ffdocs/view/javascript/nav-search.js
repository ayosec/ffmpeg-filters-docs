document.addEventListener("DOMContentLoaded", () => {
  // Check if this page contains an items tree in <nav>.
  if(document.querySelector("nav .current-version details") === null) {
    return;
  }

  // Don't add the input in the version-front page.
  if(document.querySelector("main.version-front") !== null) {
    return;
  }

  // Add an icon for the search input.
  let search = document.createElement("INPUT");
  search.placeholder = "Search";
  search.accessKey = "s";
  search.classList.add("search");

  // Update visible items when the input is modified.
  window.navSearchInput = new NavSearchInput(search);

  let labelHeader = document.querySelector(".current-version > .version-label");
  labelHeader.prepend(search);
});

class NavSearchInput extends SearchInput {
  constructor(elem) {
    super(elem);
    this.nodesState = null;
  }

  update(query) {
    super.setQuery(query);

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
    for(const elem of document.querySelectorAll("nav details a, nav details .version-label")) {
      let link = elem.innerText;
      let visible = words.every(w => link.includes(w));
      elem.classList.toggle("hidden", !visible);

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
      } else {
        elem.classList.remove("selected");
      }
    }

    // Show only <details> nodes with visible items.
    for(const elem of document.querySelectorAll("nav details")) {
      if(visibleNodes.has(elem)) {
        elem.classList.remove("hidden");
        elem.open = true;
      } else {
        elem.classList.add("hidden");
      }
    }
  }

  selectionItemsQuery() {
    return "nav details a:not(.hidden)";
  }

  selectedItemQuery() {
    return "nav a.selected";
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
    }

    for(const elem of document.querySelectorAll("nav .hidden")) {
      elem.classList.remove("hidden");
    }

    for(const elem of document.querySelectorAll("nav .selected")) {
      elem.classList.remove("selected");
    }

    this.nodesState = null;
  }

}
