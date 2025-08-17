import { useState } from "react";
import { Dropdown, DropdownItem } from "flowbite-react";
import { ChevronsUpDown } from "lucide-react";

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

	return (
		<Dropdown
			label={
				<div className="flex items-center gap-3">
					<div className="w-8 h-8 rounded-sm bg-teal-600 flex items-center justify-center text-white font-bold overflow-hidden">
						<img src="/undp.svg" alt="UNDP Logo" className="h-12 w-auto" />
					</div>
					<span className="font-medium">{selected.label}</span>
					<ChevronsUpDown className="text-gray-500" size="16" />
				</div>
			}
			inline={true}
			className="!p-0"
			arrowIcon={false}
		>
			{options.map((option: Option) => (
				<DropdownItem key={option.value} onClick={() => handleSelect(option)}>
					{option.label}
				</DropdownItem>
			))}
		</Dropdown>
	);
}
