(() => {
  const dialog = document.querySelector('.art-lightbox');
  if (!dialog) return;

  const items = [...document.querySelectorAll('.art-gallery__item')];
  const filters = [...document.querySelectorAll('.art-categories__button')];
  const description = document.querySelector('.art-category-description');
  const image = dialog.querySelector('.art-lightbox__image');
  const caption = dialog.querySelector('.art-lightbox__caption');
  let current = 0;

  function visibleItems() {
    return items.filter((item) => !item.hidden);
  }

  function filter(category) {
    const selected = filters.some((button) => button.dataset.filter === category) ? category : 'all';
    filters.forEach((button) => button.setAttribute('aria-pressed', String(button.dataset.filter === selected)));
    items.forEach((item) => { item.hidden = selected !== 'all' && item.dataset.category !== selected; });
    const label = filters.find((button) => button.dataset.filter === selected);
    description.textContent = selected === 'all' ? '所有摄影作品' : `${label.dataset.description} · ${visibleItems().length} 张演示作品`;
  }

  if (filters.length && description) {
    filters.forEach((button) => button.addEventListener('click', () => {
      filter(button.dataset.filter);
      window.history.replaceState(null, '', button.dataset.filter === 'all' ? window.location.pathname : `#${button.dataset.filter}`);
    }));
    window.addEventListener('hashchange', () => filter(window.location.hash.slice(1)));
    filter(window.location.hash.slice(1));
  }

  function show(index) {
    const visible = visibleItems();
    current = (index + visible.length) % visible.length;
    const item = visible[current];
    image.src = item.dataset.full;
    image.alt = item.querySelector('img').alt;
    caption.textContent = item.dataset.caption;
  }

  items.forEach((item) => item.addEventListener('click', () => {
    show(visibleItems().indexOf(item));
    dialog.showModal();
  }));

  dialog.querySelector('.art-lightbox__close').addEventListener('click', () => dialog.close());
  dialog.querySelector('.art-lightbox__prev').addEventListener('click', () => show(current - 1));
  dialog.querySelector('.art-lightbox__next').addEventListener('click', () => show(current + 1));

  dialog.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowLeft') show(current - 1);
    if (event.key === 'ArrowRight') show(current + 1);
  });
  dialog.addEventListener('click', (event) => {
    if (event.target === dialog) dialog.close();
  });
  dialog.addEventListener('close', () => image.removeAttribute('src'));
})();
