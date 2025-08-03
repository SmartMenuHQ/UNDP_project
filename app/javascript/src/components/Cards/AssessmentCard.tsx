import { Button, ButtonGroup, Card, HR } from "flowbite-react";
import { Trash, Pencil, Eye } from "lucide-react";

export enum AssessmentStatus {
	ACTIVE = "Active",
	DRAFT = "Draft",
}
interface AssessmentCardProps {
	title: string;
	date: string;
	description: string;
	status: AssessmentStatus;
	onEdit?: () => void;
	onView?: () => void;
	onDelete?: () => void;
}

const AssessmentCard = ({
	title,
	date,
	description,
	status,
	onView,
	onDelete,
	onEdit,
}: AssessmentCardProps) => {
	const handleEdit = () => {
		if (onEdit) {
			onEdit();
		}
	};

	const handleView = () => {
		if (onView) {
			onView();
		}
	};

	const handleDelete = () => {
		if (onDelete) {
			onDelete();
		}
	};
	return (
		<Card className="max-w-sm">
			<header className="flex justify-center items-center">
				<div>
					<time className="text-gray-500 text-xs font-semibold">{date}</time>

					<h5 className="text-2xl font-bold mt-2 tracking-tight text-gray-900">{title}</h5>
				</div>

				<span
					className={`flex self-start items-center px-2.5 py-0.5 rounded-full text-xs font-medium text-green-800 ${
						status === AssessmentStatus.ACTIVE ? "bg-green-100" : "bg-yellow-100"
					}`}
				>
					{status}
				</span>
			</header>
			<p className="font-normal text-gray-700 dark:text-gray-400">{description}</p>
			<HR className="my-0 mt-0 mx-[calc(-1*1.5rem)]" />

			<footer className="flex items-center justify-between">
				<ButtonGroup className="shadow-none w-full">
					<Button color="alternative" onClick={handleEdit}>
						<Pencil size={16} />
					</Button>
					<Button color="alternative" className="hover:text-blue-600" onClick={handleView}>
						<Eye size={16} />
					</Button>
					<Button color="alternative" className="hover:text-red-600" onClick={handleDelete}>
						<Trash size={16} />
					</Button>
				</ButtonGroup>
			</footer>
		</Card>
	);
};

export default AssessmentCard;
