document$.subscribe(() => {
  const options = [...document.querySelectorAll(".md-typeset .option")];
  if (!options.length) return;

  const kinds = ["all", ...new Set(options.map((o) => o.dataset.kind))].sort((a, b) => (a === "all" ? -1 : a.localeCompare(b)));
  const filters = document.createElement("div");
  filters.className = "filters";
  const count = document.createElement("span");
  count.className = "count";

  function apply(kind) {
    let shown = 0;
    for (const o of options) {
      o.hidden = kind !== "all" && o.dataset.kind !== kind;
      if (!o.hidden) shown++;
    }
    for (const h2 of document.querySelectorAll(".md-typeset h2")) {
      let el = h2.nextElementSibling;
      let any = false;
      while (el && el.tagName !== "H2") {
        if (el.classList.contains("option") && !el.hidden) any = true;
        el = el.nextElementSibling;
      }
      h2.hidden = !any;
    }
    count.textContent = `${shown} of ${options.length}`;
  }

  const chips = kinds.map((kind) => {
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = "chip";
    chip.textContent = kind === "all" ? "All types" : kind;
    chip.setAttribute("aria-pressed", String(kind === "all"));
    chip.addEventListener("click", () => {
      for (const c of chips) c.setAttribute("aria-pressed", String(c === chip));
      apply(kind);
    });
    return chip;
  });

  filters.append(...chips, count);
  document.querySelector(".md-typeset h1").after(filters);
  apply("all");
});
