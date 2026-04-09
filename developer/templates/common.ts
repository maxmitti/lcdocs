interface Entry {
	path: string;
	name: string;
	category: string;
	version: string;
	deprecated_version: string | null;
}

type EntryType = 'constants' | 'functions';

type category_i18n_map = {[path: string]: string[]};
type files_i18n = {
	de: string;
	en: string;
};

interface Summary {
	created: string;
	generated_from: string;
	files: {
		[directory: string]: {
			i18n: files_i18n;
			files: {[name: string]: files_i18n};
		};
	};
	category_i18n: {
		de: category_i18n_map;
		en: category_i18n_map;
	};
	script: {
		constants: Entry[];
		functions: Entry[];
	};
}

type I18n = {[key: string]: string};

let i18n: I18n;
const language = document.documentElement.lang;
let summary: Summary;

async function fetch_json_res(name: string): Promise<any> {
	return await (await fetch(`../resources/${name}.json`)).json();
}

async function fetch_i18n(): Promise<void> {
	i18n = await fetch_json_res(`${language}.i18n`);
}

async function fetch_summary(): Promise<void> {
	summary = await fetch_json_res('lcdocs_summary');
}

function entry_abs_path(rel_path: string): string {
	return `${summary.generated_from}/${rel_path.substring(0, rel_path.length - 4)}.html`;
}

function switchLanguage() {
	var loc = window.location.href;
	if (loc.match(/\/en\//))
		loc = loc.replace(/\/en\//, "/de/");
	else
		loc = loc.replace(/\/de\//, "/en/");
	window.location.href = loc;
}
