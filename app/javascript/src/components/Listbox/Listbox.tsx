"use client";

import { useState } from "react";
import { Dropdown, DropdownItem } from "flowbite-react";
import { ChevronDown } from "lucide-react";

type Option = {
	value: string;
	label: string;
};

type ListboxProps = {
	options: Option[];
	defaultValue?: Option;
	onChange?: (option: Option) => void;
};

export default function Listbox({ options, defaultValue, onChange }: ListboxProps) {
	const [selected, setSelected] = useState<Option>(defaultValue || options[0]);

	const handleSelect = (option: Option) => {
		setSelected(option);
		if (onChange) onChange(option);
	};

	const dropdownTheme = {
		floating: {
			target: "w-full",
			base: "z-10 w-fit divide-y divide-gray-100 rounded-lg shadow focus:outline-none",
			content: "py-1 text-sm text-gray-700 dark:text-gray-200",
			divider: "my-1 h-px bg-gray-100 dark:bg-gray-600",
			header: "block px-4 py-2 text-sm text-gray-700 dark:text-gray-200",
			hidden: "invisible opacity-0",
			item: {
				container: "",
				base: "flex w-full cursor-pointer items-center justify-start px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none dark:text-gray-200 dark:hover:bg-gray-600 dark:focus:bg-gray-600",
				icon: "mr-2 h-4 w-4"
			},
			style: {
				dark: "bg-gray-900 text-white dark:bg-gray-700",
				light: "border border-gray-200 bg-white text-gray-900",
				auto: "border border-gray-200 bg-white text-gray-900 dark:border-none dark:bg-gray-700 dark:text-white"
			},
			arrow: {
				base: "absolute z-10 h-2 w-2 rotate-45",
				style: {
					dark: "bg-gray-900 dark:bg-gray-700",
					light: "bg-white",
					auto: "bg-white dark:bg-gray-700"
				},
				placement: "-4px"
			}
		}
	};

	return (
		<div className="relative w-full">
			<Dropdown
				label={
					<div className="flex items-center justify-between w-full p-2 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
						<div className="flex items-center gap-3">
							<div className="w-8 h-8 rounded-lg bg-teal-500 flex items-center justify-center text-white font-bold text-sm">
								W
							</div>
							<span className="font-medium text-gray-900 truncate">{selected.label}</span>
						</div>
						<ChevronDown className="text-gray-500 ml-2 flex-shrink-0" size="16" />
					</div>
				}
				inline={true}
				arrowIcon={false}
				placement="bottom-start"
				theme={dropdownTheme}
			>
			{options.map((option: Option) => (
				<DropdownItem key={option.value} onClick={() => handleSelect(option)}>
					<div className="flex items-center gap-3">
						<div className="w-6 h-6 rounded bg-teal-500 flex items-center justify-center text-white font-bold text-xs">
							W
						</div>
						{option.label}
					</div>
				</DropdownItem>
			))}
		</Dropdown>
		</div>
	);
}
