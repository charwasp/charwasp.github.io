function escape(s) {
	s = s.replace(/&/g, '&amp;').replace(/'/g, '&apos;').replace(/"/g, '&quot;')
	s = s.replace(/</g, '&lt;').replace(/>/g, '&gt;')
	s = s.replace(/\r\n/g, '&#13;').replace(/[\r\n]/g, '&#13;');
	return s;
}

const keywordFilter = {keyword: ''};
const categoryFilter = {
	secret: false,
	chaos: false,
	inst: false,
	vocal: false,
	boost: false,
};
const levelFilter = {
	1: false,
	2: false,
	3: false,
	4: false,
	5: false,
	6: false,
	7: false,
	8: false,
	9: false,
	10: false,
	11: false,
	12: false,
	13: false,
};

const filterStyle = document.createElement('style');
document.head.appendChild(filterStyle);
const filterSheet = filterStyle.sheet;
let hasFilter = false;

function reapplyFilter() {
	let keywordSelector = '';
	if (keywordFilter.keyword) {
		keyword = escape(keywordFilter.keyword);
		for (const keywordIndex of [1, 2, 3, 4]) {
			const attribute = `data-keyword-${keywordIndex}`;
			keywordSelector += `:not([${attribute}][${attribute}*="${keyword}" i])`;
		}
	}

	let categorySelector = '';
	for (const category in categoryFilter) {
		if (categoryFilter[category]) {
			categorySelector += `:not([data-${category}="1"])`;
		}
	}

	let levelSelector = '';
	for (const level in levelFilter) {
		if (levelFilter[level]) {
			levelSelector += `:not([data-levels~="${level}"])`;
		}
	}

	const selectors = [keywordSelector, categorySelector, levelSelector].filter(Boolean);
	const selector = selectors.map(s => '#music-table > tbody > tr' + s).join(', ');
	if (hasFilter) {
		filterSheet.deleteRule(0);
		hasFilter = false;
	}
	if (selector) {
		filterSheet.insertRule(`${selector} { display: none; }`);
		hasFilter = true;
	}
}

window.addEventListener('DOMContentLoaded', () => {
	document.getElementById('filter-keyword').addEventListener('input', event => {
		keywordFilter.keyword = event.target.value;
		reapplyFilter();
	});
	for (const category in categoryFilter) {
		document.getElementById(`filter-${category}`).addEventListener('change', event => {
			categoryFilter[category] = event.target.checked;
			reapplyFilter();
		});
	}
	for (const level in levelFilter) {
		document.getElementById(`filter-level-${level}`).addEventListener('change', event => {
			levelFilter[level] = event.target.checked;
			reapplyFilter();
		});
	}

	const filterClasses = document.getElementById('filter').classList;
	document.getElementById('filter-button').addEventListener('click', () => {
		if (filterClasses.contains('hidden')) {
			filterClasses.remove('hidden');
		} else {
			filterClasses.add('hidden');
		}
	});
});
