type ListSorting = 'by_category' | 'by_name';

enum ItemState {
	AVAILABLE = 0,
	NEW,
	DEPRECATED,
}

interface Item {
	name: string;
	state: ItemState;
	path: string;
}

type FolderMap = Map<string, Folder>;

interface Folder {
	folders: FolderMap;
	items: Item[];
	path?: string;
	open?: boolean;
}

function open_bullet(bullet: HTMLImageElement): void {
	bullet.src = '../resources/images/bullet_folder_open.gif';
	bullet.alt = '-';
	bullet.title = i18n['collapse'];
}

function close_bullet(bullet: HTMLImageElement): void {
	bullet.src = '../resources/images/bullet_folder.gif';
	bullet.alt = '+';
	bullet.title = i18n['expand'];
}

function collapse_tree(event: MouseEvent): void {
	const bullet = event.target as HTMLImageElement;
	const ul = (bullet.parentNode as HTMLUListElement).getElementsByTagName('ul')[0];
	if (bullet.alt == '+') {
		open_bullet(bullet);
		ul.style.display = '';
	} else {
		close_bullet(bullet);
		ul.style.display = 'none';
	}
}

function create_folder_structure_by_category(current_folder: Folder, entry: Entry, category: string[], state: ItemState): void {
	if (category.length == 0) {
		current_folder.items.push({name: entry.name, state: state, path: entry_abs_path(entry.path)});
		return;
	}
	
	const target_category = category[0];
	if (!current_folder.folders.has(target_category)) {
		current_folder.folders.set(target_category, {folders: new Map(), items: []});
	}
	create_folder_structure_by_category(current_folder.folders.get(target_category), entry, category.slice(1), state);
}

function sort_folder_map(source_folder_map: FolderMap): FolderMap {
	// recurse into subfolders
	for (const folder of source_folder_map.values()) {
		folder.folders = sort_folder_map(folder.folders);
	}
	
	const sorted_folder_map: FolderMap = new Map();
	Array.from(source_folder_map.keys()).sort().forEach((name) => {
		sorted_folder_map.set(name, source_folder_map.get(name));
	});
	
	return sorted_folder_map;
}

function create_list(parent_folder: Folder, entry_type: EntryType, sorting: ListSorting): void {
	const list: Folder = {folders: new Map(), items: []};
	
	// build a list of versions in which summary entries were added and deprecated
	let versions_unsorted = [];
	for (const entry of summary.script[entry_type]) {
		// add version to the list if it doesn't already exist
		if (!versions_unsorted.includes(entry.version)) {
			versions_unsorted.push(entry.version);
		}
		
		// add the deprecated version too in case an entry got deprecated in a version in which no entries were added
		// don't add unknown as version, because such entries are handled when they are added to the folders
		if (entry.deprecated_version && entry.deprecated_version != 'unknown') {
			if (!versions_unsorted.includes(entry.deprecated_version)) {
				versions_unsorted.push(entry.deprecated_version);
			}
		}
	}
	
	// pre-sort versions in case there are different version strings with the same content version but e.g. different engine versions
	versions_unsorted = versions_unsorted.sort();
	
	const versions_sorted: [string, number[]][] = [];
	for (const version_string of versions_unsorted) {
		const version_parsed: number[] = [];
		
		// get the content version and split it for sorting
		for (const part of version_string.split(' ')[0].split('.')) {
			version_parsed.push(parseInt(part));
		}
		
		versions_sorted.push([version_string, version_parsed]);
	}
	
	// sort versions ascending for all 4 content version parts
	for (let i = 3; i >= 0; i--) {
		versions_sorted.sort((a, b) => a[1][i] - b[1][i]);
	}
	
	// create sorted array of versions and create folders in descending order
	const versions: string[] = [];
	const last = versions_sorted.length - 1;
	for (let i = last; i >= 0; i--) {
		const version_string = versions_sorted[i][0];
		
		versions.push(version_string);

		// open last by default
		list.folders.set(version_string, {folders: new Map(), items: [], open: i == last});
	}
	
	
	for (const entry of summary.script[entry_type]) {
		// if the version in which the entry got deprecated is unknown, show the entry as deprecated in every version, except for the version in which it was added, where it is shown as new
		let deprecated = entry.deprecated_version == 'unknown';
		
		// add the entry to the folders of the version in which it was added and all later versions
		for (let i = versions.indexOf(entry.version); i >= 0; i--) {
			const version = versions[i];
			
			// if the entry got deprecated in this version, mark it as deprecated for the current and all later versions
			if (version == entry.deprecated_version) {
				deprecated = true;
			}
			
			let state: ItemState;
			if (version == entry.version) {
				state = ItemState.NEW;
			} else if (deprecated) {
				state = ItemState.DEPRECATED;
			} else {
				state = ItemState.AVAILABLE;
			}
			
			const version_folder = list.folders.get(version);
			
			switch (sorting) {
			case 'by_category':
				create_folder_structure_by_category(version_folder, entry, summary.category_i18n[language][entry.category], state);
				version_folder.folders = sort_folder_map(version_folder.folders);
				break;
			case 'by_name':
				version_folder.items.push({name: entry.name, state: state, path: entry_abs_path(entry.path)});
				break;
			}
		}
	}
	
	parent_folder.folders.set(i18n[entry_type] + ' ' + i18n[sorting], list);
}

function render_folder(folder: Folder, folder_name: string, parent_node: HTMLUListElement, first=true): void {
	const folder_node = document.createElement('ul');
	
	const folder_item_list_node = document.createElement('ul');
	
	const folder_bullet = document.createElement('img');
	folder_bullet.className = 'folder-bullet';
	if (first || folder.open) {
		open_bullet(folder_bullet);
	} else {
		close_bullet(folder_bullet);
		folder_item_list_node.style.display = 'none';
	}
	folder_bullet.addEventListener('click', collapse_tree);
	folder_node.appendChild(folder_bullet);
	
	let folder_text_parent: HTMLElement;
	
	if (folder.path) {
		const folder_anchor = document.createElement('a');
		folder_anchor.href = folder.path;
		folder_node.appendChild(folder_anchor);
		
		folder_text_parent = folder_anchor;
	} else {
		folder_text_parent = folder_node;
	}
	
	folder_text_parent.appendChild(document.createTextNode(folder_name));
	
	for (const item of folder.items) {
		const item_li = document.createElement('li');
		
		const item_anchor = document.createElement('a');
		item_anchor.href = item.path;
		
		const item_bullet = document.createElement('img');
		item_bullet.className = 'bullet';
		item_bullet.src = '../resources/images/bullet_sheet.gif';
		item_bullet.alt = '-';
		item_anchor.appendChild(item_bullet);
		
		let item_name_parent: HTMLElement;
		switch (item.state) {
		case ItemState.AVAILABLE:
			item_name_parent = item_anchor;
			break;
		case ItemState.NEW:
			item_name_parent = document.createElement('b');
			item_anchor.appendChild(item_name_parent);
			break;
		case ItemState.DEPRECATED:
			item_name_parent = document.createElement('s');
			item_anchor.appendChild(item_name_parent);
			break;
		}
		item_name_parent.appendChild(document.createTextNode(item.name));
		
		item_li.appendChild(item_anchor);
		
		folder_item_list_node.appendChild(item_li);
	}

	for (const [subfolder_name, subfolder] of folder.folders) {
		render_folder(subfolder, subfolder_name, folder_item_list_node, false);
	}
	
	folder_node.appendChild(folder_item_list_node);
	
	parent_node.appendChild(folder_node);
}

(async () => {
	await Promise.all([
		fetch_i18n(),
		fetch_summary(),
	]);
	
	const folders_ul = document.getElementById('folders') as HTMLUListElement;
	
	const root_folder: Folder = {folders: new Map(), items: []};
	
	for (const [dir_name, dir] of Object.entries(summary.files)) {
		const folder: Folder = {folders: new Map(), items: [], path: `${summary.generated_from}/${dir_name}`};
		
		for (const [file_name, file_i18n] of Object.entries(dir.files)) {
			folder.items.push({
				name: file_i18n[language],
				state: ItemState.AVAILABLE,
				path: entry_abs_path(`${dir_name}/${file_name}`),
			});
		}
		
		root_folder.folders.set(dir.i18n[language], folder);
	}
	
	const script_folder: Folder = root_folder.folders.get(i18n['script']) ?? {folders: new Map(), items: [], path: `${summary.generated_from}/script`};
	create_list(script_folder, 'functions', 'by_category');
	create_list(script_folder, 'functions', 'by_name');
	create_list(script_folder, 'constants', 'by_category');
	create_list(script_folder, 'constants', 'by_name');
	root_folder.folders.set(i18n['script'], script_folder);
	
	for (const [folder_name, folder] of root_folder.folders) {
		render_folder(folder, folder_name, folders_ul);
	}
	
	document.getElementById('loading-spinner').style.display = 'none';
})();
