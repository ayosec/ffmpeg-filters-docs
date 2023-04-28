document.addEventListener("DOMContentLoaded", () => {
  let front = document.querySelector("main.version-front")
  if(front === null) {
    return;
  }

  // Add an icon for the search input.
  let search = document.createElement("INPUT");
  search.placeholder = "Search";
  search.accessKey = "s";
  search.classList.add("search");

  // <span> to show the </> shortcut.
  let shortcut = document.createElement("SPAN");
  shortcut.classList.add("shortcut");

  // Update visible items when the input is modified.
  window.frontSearchInput = new FrontSearchInput(search);

  // Use a <section> for the new elements.
  let section = document.createElement("SECTION");
  section.classList.add("search");

  section.appendChild(search);
  section.appendChild(shortcut);

  front.prepend(section);
});

class FrontSearchInput {
  constructor(elem) {
    this.items = null;

    elem.addEventListener("input", () => {
      this.update(elem.value.trim());
    });

    elem.addEventListener("keydown", (event) => {
      this.onKeyDown(event);
    });


    // Focus the search input on "/".
    document.body.addEventListener("keydown", (event) => {
      if(event.target.tagName !== "INPUT" && event.key === "/") {
        event.preventDefault();
        elem.focus();
      }
    });
  }

  update(query) {
    if(query === "") {
      this.restoreView();
      return;
    }

    if(this.items === null) {
      this.collectItemData();
    }

    // Set the "list" class to reuse the styles for the list.
    let container = document.querySelector("main.version-front");
    container.classList.add("list");

    // Continer for the results.
    let results = document.querySelector("dl.search-results");
    if(results === null) {
      results = document.createElement("DL");
      results.classList.add("search-results");
      results.classList.add("items");
      container.appendChild(results);
    } else {
      results.innerHTML = "";
    }

    // Search items and add them to the list in alphabetical order.
    let words = query.split(/ +/);
    let foundItems = [];
    for(const item of this.items) {
      let visible = words.every(w => item.name.includes(w) || item.description.includes(w));

      if(visible) {
        foundItems.push(item);
      }
    }

    foundItems.sort((a, b) => a.name.localeCompare(b.name));

    for(const item of foundItems) {
      let anchor = document.createElement("A");
      anchor.href = item.href;
      anchor.appendChild(document.createTextNode(item.name));

      let dt = document.createElement("DT");
      dt.appendChild(anchor);

      let dd = document.createElement("DD");
      dd.appendChild(document.createTextNode(item.description));

      results.appendChild(dt);
      results.appendChild(dd);
    }
  }

  // Extract item data from the links in the <nav>.
  collectItemData() {
    let items = []
    for(const elem of document.querySelectorAll("nav details a")) {
      // To get the name of the item we have to use firstChild, since some
      // Chromium-based browser does not support innerText on hidden elements.
      let name = elem.firstChild.nodeValue;

      items.push({
        name,
        description: elem.title,
        href: elem.href,
      });
    }

    this.items = items;
  }

  onKeyDown(event) {
    let direction;
    switch(event.key) {
      case "ArrowUp":
        this.moveSelection(-1);
        break;

      case "ArrowDown":
        this.moveSelection(1);
        break;

      case "Enter":
        let inNewWindow = event.getModifierState("Control");
        this.openSelection(inNewWindow);
        break;

      default:
        return;
    }

    event.preventDefault();
  }

  moveSelection(direction) {
    let elems = document.querySelectorAll("dl.search-results dt")

    if(elems.length === 0) { return; }

    let foundIndex = -1;
    for(let index = 0; index < elems.length; index++) {
      if(elems[index].classList.contains("selected")) {
        elems[index].classList.remove("selected");
        foundIndex = index;
        break;
      }
    }

    foundIndex = foundIndex + direction;
    if(foundIndex < 0) {
      foundIndex = elems.length - 1;
    } else if(foundIndex >= elems.length) {
      foundIndex = 0;
    }

    elems[foundIndex].classList.add("selected");
  }

  openSelection(inNewWindow) {
    let elem = document.querySelector("dl.search-results dt.selected a");
    if(elem === null) { return; }

    if(inNewWindow) {
      window.open(elem.href, "_blank");
    } else {
      location.href = elem.href;
    }
  }

  restoreView() {
    let container = document.querySelector("main.version-front");
    container.classList.remove("list");

    let results = document.querySelector("dl.search-results");
    results.remove();
  }
}
