function create_table(entryTable: HTMLTableElement) {
	for (const type of Object.keys(summary.script)) {
		for (const item of summary.script[type]) {
			const entry_tr = document.createElement('tr');
			
			const name_td = document.createElement('td');
			const anchor_element = document.createElement('a');
			anchor_element.href = entry_abs_path(item.path);
			if (item.deprecated_version === null) {
				anchor_element.appendChild(document.createTextNode(item.name));
			} else {
				const strikeout_element = document.createElement('s');
				strikeout_element.appendChild(document.createTextNode(item.name));
				anchor_element.appendChild(strikeout_element);
			}
			name_td.appendChild(anchor_element);
			entry_tr.appendChild(name_td);
			
			const type_td = document.createElement('td');
			switch (type) {
				case 'functions':
					type_td.appendChild(document.createTextNode(i18n['function']));
					entry_tr.dataset['type'] = 'function';
				break;
				case 'constants':
					entry_tr.dataset['type'] = 'constant';
					type_td.appendChild(document.createTextNode(i18n['constant']));
				break;
			}
			entry_tr.appendChild(type_td);
			
			const categoryTd = document.createElement('td');
			categoryTd.appendChild(document.createTextNode(summary.category_i18n[language][item.category].join('/')));
			entry_tr.appendChild(categoryTd)
			
			const versionTd = document.createElement('td');
			versionTd.appendChild(document.createTextNode(item.version));
			entry_tr.appendChild(versionTd);
			
			entryTable.appendChild(entry_tr);
		}
	}
}

const debounce = (func, wait) => {
	let timeout;
	
	return function executedFunction(...args) {
		const later = () => {
			clearTimeout(timeout);
			func(...args);
		};
		
		clearTimeout(timeout);
		timeout = setTimeout(later, wait);
	};
};

function perform_search(searchField: HTMLInputElement, typeCheckboxes: HTMLCollectionOf<HTMLInputElement>, entries: HTMLCollectionOf<HTMLTableRowElement>): void {
	const search = searchField.value.toUpperCase()
	const enabled_types = [];
	for (let i = 0; i < typeCheckboxes.length; i++) {
		const checkbox = typeCheckboxes[i];
		if (checkbox.checked) {
			enabled_types.push(checkbox.value)
		}
	}

	let currentVisibleRow = 0
	for (let i = 0; i < entries.length; i++) {
		const row = entries[i];
		const nameTd = row.getElementsByTagName('td')[0];
		if (nameTd) {
			const value = nameTd.textContent || nameTd.innerText;
			if (value.toUpperCase().indexOf(search) > -1 && enabled_types.indexOf(row.dataset['type']) > -1) {
				if (++currentVisibleRow%2 === 0) {
					// Mark even rows
					row.classList.add('mark-even-row');
				} else {
					row.classList.remove('mark-even-row');
				}
				row.hidden = false;
			} else {
				row.hidden = true;
			}
		}
	}
}

(async () => {
	await Promise.all([
		fetch_i18n(),
		fetch_summary(),
	]);

	const searchbar = document.getElementById('search-bar') as HTMLFieldSetElement;
	const search_field = document.getElementById('search-field') as HTMLInputElement;
	const type_checkboxes = document.getElementsByClassName('type-checkbox') as HTMLCollectionOf<HTMLInputElement>;
	const entry_table = document.getElementById('search-results') as HTMLTableElement;
	create_table(entry_table);

	const entries = entry_table.getElementsByTagName('tr');
	perform_search(search_field, type_checkboxes, entries);
	searchbar.addEventListener('change', debounce(() => perform_search(search_field, type_checkboxes, entries), 250));
	searchbar.addEventListener('keyup', debounce(() => perform_search(search_field, type_checkboxes, entries), 250));
	entry_table.style.display = '';

	document.getElementById('loading-spinner').style.display = 'none';
})();
