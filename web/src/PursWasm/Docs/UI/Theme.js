// Theme persistence. The initial `.dark` class is set by an inline script in
// index.html (before paint); this module reads and toggles it at runtime.

export const readDark = () => document.documentElement.classList.contains("dark");

export const applyDark = (dark) => () => {
  const el = document.documentElement;
  if (dark) el.classList.add("dark");
  else el.classList.remove("dark");
  try {
    localStorage.setItem("theme", dark ? "dark" : "light");
  } catch (e) {}
};
