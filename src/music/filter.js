let filterButton;

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
		for (const data of ['name', 'artist', 'keyword-1', 'keyword-2', 'keyword-3', 'keyword-4']) {
			const attribute = `data-${data}`;
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
		filterButton.classList.remove('has-filter');
	}
	if (selector) {
		filterSheet.insertRule(`${selector} { display: none; }`);
		hasFilter = true;
		filterButton.classList.add('has-filter');
	}
}

window.addEventListener('load', () => {
	const filterKeyword = document.getElementById('filter-keyword');
	filterKeyword.addEventListener('input', () => {
		keywordFilter.keyword = filterKeyword.value;
		reapplyFilter();
	});
	keywordFilter.keyword = filterKeyword.value;

	for (const category in categoryFilter) {
		const element = document.getElementById(`filter-${category}`);
		element.addEventListener('change', () => {
			categoryFilter[category] = element.checked;
			reapplyFilter();
		});
		categoryFilter[category] = element.checked;
	}

	for (const level in levelFilter) {
		const element = document.getElementById(`filter-level-${level}`);
		element.addEventListener('change', () => {
			levelFilter[level] = element.checked;
			reapplyFilter();
		});
		levelFilter[level] = element.checked;
	}

	const filterClasses = document.getElementById('filter').classList;
	filterButton = document.getElementById('filter-button');
	filterButton.addEventListener('click', () => {
		if (filterClasses.contains('hidden')) {
			filterClasses.remove('hidden');
		} else {
			filterClasses.add('hidden');
		}
	});

	const resetButton = document.getElementById('filter-reset');
	resetButton.addEventListener('click', () => {
		filterKeyword.value = '';
		keywordFilter.keyword = '';
		for (const category in categoryFilter) {
			const element = document.getElementById(`filter-${category}`);
			element.checked = false;
			categoryFilter[category] = false;
		}
		for (const level in levelFilter) {
			const element = document.getElementById(`filter-level-${level}`);
			element.checked = false;
			levelFilter[level] = false;
		}
		reapplyFilter();
	});

	reapplyFilter();
});
