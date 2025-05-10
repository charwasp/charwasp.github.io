function sortClassName(ascending) {
	return ascending ? 'sort-ascending' : 'sort-descending';
}

const currentSort = { element: null, ascending: true };
function updateCurrentSort(element) {
	currentSort.element?.classList.remove(sortClassName(currentSort.ascending));
	if (currentSort.element === element) {
		currentSort.ascending = !currentSort.ascending;
	} else {
		currentSort.element = element;
		currentSort.ascending = true;
	}
	currentSort.element.classList.add(sortClassName(currentSort.ascending));
}

function sortById(tbody) {
	const items = [];
	// The Array.from() creates an copy because the NodeList gets modified when elements are removed.
	for (const element of Array.from(tbody.getElementsByTagName('tr'))) {
		element.remove();
		const id = Number(element.getElementsByTagName('th')[0].textContent);
		items.push({ id, element });
	}
	if (currentSort.ascending) {
		items.sort(({ id: a }, { id: b }) => a - b);
	} else {
		items.sort(({ id: a }, { id: b }) => b - a);
	}
	const fragment = document.createDocumentFragment();
	fragment.append(...items.map(({ element }) => element));
	tbody.appendChild(fragment);
}

function q(c) {
	return c.charCodeAt(0);
}
function charOrdinal(char) {
	const c = q(char);
	if (c === q('-')) {
		return q('一') - 0.5;
	}
	if (c === q('～')) {
		return q('~');
	}
	if (c >= q('a') && c <= q('z')) {
		return c - q('a') + q('A');
	}
	if (c >= q('α') && c <= q('ω')) {
		return c - q('α') + q('Α');
	}
	if (c >= q('ァ') && c <= q('ヺ')) {
		return c - q('ァ') + q('ぁ');
	}
	if (c >= q('ɐ') && c <= q('ʯ')) {
		return c + 0x10000;
	}
	return c;
}
function stringCompare(a, b) {
	a = a.replace(/['\s]/g, '');
	b = b.replace(/['\s]/g, '');
	const minLength = Math.min(a.length, b.length);
	for (let i = 0; i < minLength; i++) {
		const aChar = charOrdinal(a[i]);
		const bChar = charOrdinal(b[i]);
		if (aChar !== bChar) {
			return aChar - bChar;
		}
	}
	return a.length - b.length;
}

function sortBy(tbody, className) {
	const items = [];
	for (const element of Array.from(tbody.getElementsByTagName('tr'))) {
		element.remove();
		const value = element.getElementsByClassName(className)[0].textContent;
		const id = Number(element.getElementsByTagName('th')[0].textContent);
		items.push({ id, value, element });
	}
	if (currentSort.ascending) {
		items.sort((a, b) => stringCompare(a.value, b.value) || a.id - b.id);
	} else {
		items.sort((a, b) => stringCompare(b.value, a.value) || b.id - a.id);
	}
	for (const {element} of items) {
		tbody.appendChild(element);
	}
}

function sortByName(tbody) {
	sortBy(tbody, 'name');
}

function sortByArtist(tbody) {
	sortBy(tbody, 'artist');
}

window.addEventListener('DOMContentLoaded', () => {
	const tbody = document.getElementById('music-table').getElementsByTagName('tbody')[0];
	document.getElementById('id').addEventListener('click', event => {
		updateCurrentSort(event.target);
		sortById(tbody)
	});
	document.getElementById('name').addEventListener('click', event => {
		updateCurrentSort(event.target);
		sortByName(tbody)
	});
	document.getElementById('artist').addEventListener('click', event => {
		updateCurrentSort(event.target);
		sortByArtist(tbody)
	});
	updateCurrentSort(document.getElementById('id'));
	sortById(tbody);
});
