"use client";

import React, { useState } from "react";
import { useNavigate, RouteObject } from "react-router";
import { Card, Table, TableHead, TableHeadCell, TableBody, TableRow, TableCell, Badge } from "flowbite-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import RouteGuard from "../components/RouteGuard";
import {
	Building2,
	Users,
	Activity,
	TrendingUp,
	Search,
	Filter,
	ArrowUpDown,
	Eye,
	Calendar,
	MapPin,
	CheckCircle,
	Clock,
	AlertTriangle,
	UserCheck,
	Trash2,
} from "lucide-react";

// Static data based on Swagger documentation
const staticBusinesses = [
	{
		id: 232,
		email_address: "willie@schuster-barton.example",
		first_name: "Effie",
		last_name: "Marks",
		full_name: "Effie Marks",
		display_name: "Effie Marks",
		admin: false,
		profile_completed: true,
		default_language: "en",
		country: {
			id: 210,
			name: "United States",
			code: "USA"
		},
		created_at: "2024-11-15T08:13:36.552Z",
		updated_at: "2024-12-10T08:13:36.552Z",
		response_sessions_count: 3,
		completed_sessions_count: 2,
		latest_activity: "2024-12-10T08:13:36.552Z",
		total_assessments: 2
	},
	{
		id: 233,
		email_address: "rosalina.koch@hand.test",
		first_name: "Lewis",
		last_name: "Haley",
		full_name: "Lewis Haley",
		display_name: "Lewis Haley",
		admin: false,
		profile_completed: true,
		default_language: "en",
		country: {
			id: 211,
			name: "China",
			code: "CHN"
		},
		created_at: "2024-10-20T08:13:36.552Z",
		updated_at: "2024-12-08T14:22:10.330Z",
		response_sessions_count: 5,
		completed_sessions_count: 4,
		latest_activity: "2024-12-08T14:22:10.330Z",
		total_assessments: 3
	},
	{
		id: 254,
		email_address: "merle@ziemann-hills.test",
		first_name: "Bennie",
		last_name: "King",
		full_name: "Bennie King",
		display_name: "Bennie King",
		admin: false,
		profile_completed: true,
		default_language: "en",
		country: {
			id: 224,
			name: "United States",
			code: "USA"
		},
		created_at: "2024-09-12T10:45:22.100Z",
		updated_at: "2024-12-05T16:30:45.220Z",
		response_sessions_count: 2,
		completed_sessions_count: 1,
		latest_activity: "2024-12-05T16:30:45.220Z",
		total_assessments: 1
	},
	{
		id: 263,
		email_address: "noe_williamson@romaguera.test",
		first_name: "Jane",
		last_name: "Smith",
		full_name: "Jane Smith",
		display_name: "Jane Smith",
		admin: false,
		profile_completed: true,
		default_language: "es",
		country: {
			id: 230,
			name: "United States",
			code: "USA"
		},
		created_at: "2024-08-05T14:20:30.750Z",
		updated_at: "2024-12-12T09:15:20.890Z",
		response_sessions_count: 7,
		completed_sessions_count: 6,
		latest_activity: "2024-12-12T09:15:20.890Z",
		total_assessments: 4
	},
	{
		id: 294,
		email_address: "denver_goldner@stamm.test",
		first_name: "Terrie",
		last_name: "Kautzer",
		full_name: "Terrie Kautzer",
		display_name: "Terrie Kautzer",
		admin: false,
		profile_completed: true,
		default_language: "en",
		country: {
			id: 248,
			name: "United States",
			code: "USA"
		},
		created_at: "2024-07-18T11:35:15.400Z",
		updated_at: "2024-11-28T13:42:55.670Z",
		response_sessions_count: 4,
		completed_sessions_count: 3,
		latest_activity: "2024-11-28T13:42:55.670Z",
		total_assessments: 2
	}
];

const staticStats = {
	total_businesses: staticBusinesses.length,
	active_businesses: staticBusinesses.filter(b => 
		new Date(b.latest_activity) > new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
	).length,
	total_sessions: staticBusinesses.reduce((sum, b) => sum + b.response_sessions_count, 0),
	completed_assessments: staticBusinesses.reduce((sum, b) => sum + b.completed_sessions_count, 0),
	completion_rate: Math.round(
		(staticBusinesses.reduce((sum, b) => sum + b.completed_sessions_count, 0) /
		staticBusinesses.reduce((sum, b) => sum + b.response_sessions_count, 0)) * 100
	)
};

const Businesses: React.FC = () => {
	const [businesses] = useState(staticBusinesses);
	const [stats] = useState(staticStats);
	const [searchTerm, setSearchTerm] = useState("");
	const [sortBy, setSortBy] = useState("created_at");
	const [sortOrder, setSortOrder] = useState<"asc" | "desc">("desc");
	const [currentPage, setCurrentPage] = useState(1);
	const itemsPerPage = 10;

	const navigate = useNavigate();

	const filteredBusinesses = businesses.filter(business =>
		business.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
		business.email_address.toLowerCase().includes(searchTerm.toLowerCase())
	);

	const sortedBusinesses = [...filteredBusinesses].sort((a, b) => {
		const aValue = sortBy === "created_at" ? new Date(a.created_at).getTime() : a.display_name;
		const bValue = sortBy === "created_at" ? new Date(b.created_at).getTime() : b.display_name;
		
		if (sortOrder === "asc") {
			return aValue < bValue ? -1 : 1;
		}
		return aValue > bValue ? -1 : 1;
	});

	// Pagination
	const totalPages = Math.ceil(sortedBusinesses.length / itemsPerPage);
	const startIndex = (currentPage - 1) * itemsPerPage;
	const paginatedBusinesses = sortedBusinesses.slice(startIndex, startIndex + itemsPerPage);

	const handleSort = (field: string) => {
		if (sortBy === field) {
			setSortOrder(sortOrder === "asc" ? "desc" : "asc");
		} else {
			setSortBy(field);
			setSortOrder("desc");
		}
		setCurrentPage(1); // Reset to first page when sorting
	};

	const formatDate = (dateString: string) => {
		return new Date(dateString).toLocaleDateString("en-US", {
			year: "numeric",
			month: "short",
			day: "numeric",
		});
	};

	const getActivityStatus = (latestActivity: string) => {
		const activityDate = new Date(latestActivity);
		const now = new Date();
		const daysDiff = Math.floor((now.getTime() - activityDate.getTime()) / (1000 * 3600 * 24));

		if (daysDiff <= 7) return { color: "success", label: "Active", icon: CheckCircle };
		if (daysDiff <= 30) return { color: "warning", label: "Recent", icon: Clock };
		return { color: "gray", label: "Inactive", icon: AlertTriangle };
	};

	return (
		<RouteGuard requireAdmin={true}>
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				{/* Header */}
				<div className="mb-8">
					<h1 className="text-2xl font-bold text-gray-900">Businesses</h1>
					<p className="text-gray-600 mt-1">View and manage businesses registered on the platform.</p>
				</div>

				{/* Stats Cards */}
				<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<div className="flex items-center">
							<div className="p-3 rounded-full bg-purple-100 mr-4">
								<Building2 className="w-6 h-6 text-purple-600" />
							</div>
							<div>
								<p className="text-sm font-medium text-gray-600">Total Businesses</p>
								<p className="text-2xl font-medium text-gray-900">{stats.total_businesses}</p>
							</div>
						</div>
					</div>

					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<div className="flex items-center">
							<div className="p-3 rounded-full bg-green-100 mr-4">
								<Activity className="w-6 h-6 text-green-600" />
							</div>
							<div>
								<p className="text-sm font-medium text-gray-600">Active (30 days)</p>
								<p className="text-2xl font-medium text-gray-900">{stats.active_businesses}</p>
							</div>
						</div>
					</div>

					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<div className="flex items-center">
							<div className="p-3 rounded-full bg-purple-100 mr-4">
								<Users className="w-6 h-6 text-purple-600" />
							</div>
							<div>
								<p className="text-sm font-medium text-gray-600">Total Sessions</p>
								<p className="text-2xl font-medium text-gray-900">{stats.total_sessions}</p>
							</div>
						</div>
					</div>

					<div className="bg-white rounded-lg border border-gray-200 p-6">
						<div className="flex items-center">
							<div className="p-3 rounded-full bg-orange-100 mr-4">
								<TrendingUp className="w-6 h-6 text-orange-600" />
							</div>
							<div>
								<p className="text-sm font-medium text-gray-600">Completion Rate</p>
								<p className="text-2xl font-medium text-gray-900">{stats.completion_rate}%</p>
							</div>
						</div>
					</div>
				</div>

				{/* Search and Filters */}
				<div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
					<div className="flex gap-4">
						<div className="flex-1">
							<div className="relative">
								<Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
								<input
									type="text"
									placeholder="Search businesses..."
									value={searchTerm}
									onChange={(e) => setSearchTerm(e.target.value)}
									className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								/>
							</div>
						</div>
						<button className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
							<Filter className="w-4 h-4 mr-2" />
							Filter
						</button>
					</div>
				</div>

				{/* Businesses Table */}
				<div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
					<Table>
						<TableHead>
							<TableRow className="bg-gray-50">
								<TableHeadCell className="px-4 py-3 text-left text-sm font-medium text-gray-700">
									Business
								</TableHeadCell>
								<TableHeadCell className="px-4 py-3 text-left text-sm font-medium text-gray-700">
									Owner
								</TableHeadCell>
								<TableHeadCell className="px-4 py-3 text-left text-sm font-medium text-gray-700">
									Status
								</TableHeadCell>
								<TableHeadCell className="px-4 py-3 text-left text-sm font-medium text-gray-700">
									Created
								</TableHeadCell>
								<TableHeadCell className="px-4 py-3 text-left text-sm font-medium text-gray-700">
									Details
								</TableHeadCell>
								<TableHeadCell className="px-4 py-3 text-left text-sm font-medium text-gray-700">
									Actions
								</TableHeadCell>
							</TableRow>
						</TableHead>
						<TableBody>
								{paginatedBusinesses.map((business) => {
									const activityStatus = getActivityStatus(business.latest_activity);
									const StatusIcon = activityStatus.icon;
									return (
										<TableRow key={business.id} className="hover:bg-gray-50 transition-colors border-b border-gray-100">
											<TableCell className="px-4 py-4">
												<div className="flex items-center space-x-3">
													<div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
														<Building2 className="w-4 h-4 text-purple-600" />
													</div>
													<span className="font-medium text-gray-900">{business.display_name}</span>
												</div>
											</TableCell>
											<TableCell className="px-4 py-4">
												<div className="flex items-center space-x-2">
													<div className="w-8 h-8 bg-purple-600 rounded-full flex items-center justify-center text-white text-sm font-medium">
														{business.first_name?.charAt(0) || business.display_name?.charAt(0) || 'B'}
													</div>
													<span className="text-gray-700">{business.display_name}</span>
												</div>
											</TableCell>
											<TableCell className="px-4 py-4">
												<span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium whitespace-nowrap ${
													activityStatus.color === 'success'
														? 'bg-green-100 text-green-800'
														: activityStatus.color === 'warning'
														? 'bg-red-100 text-red-800'
														: 'bg-green-100 text-green-800'
												}`}>
													{activityStatus.label}
												</span>
											</TableCell>
											<TableCell className="px-4 py-4 text-gray-500">
												<div className="flex items-center space-x-1">
													<Calendar className="w-4 h-4" />
													<span>{formatDate(business.created_at)}</span>
												</div>
											</TableCell>
											<TableCell className="px-4 py-4 text-gray-500">
												<div className="text-sm">
													<span className="font-medium text-gray-700">{business.response_sessions_count}</span> sessions, <span className="font-medium text-gray-700">{business.completed_sessions_count}</span> completed
												</div>
											</TableCell>
											<TableCell className="px-4 py-4">
												<button 
													onClick={() => navigate(`/app/businesses/${business.id}`)}
													className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
												>
													<Eye className="w-4 h-4 mr-2" />
													View Details
												</button>
											</TableCell>
										</TableRow>
									);
								})}
						</TableBody>
					</Table>

					{/* Pagination */}
					{totalPages > 1 && (
						<div className="flex items-center justify-between border-t border-gray-200 px-6 py-3">
							<div className="text-sm text-gray-700">
								Showing {startIndex + 1} to {Math.min(startIndex + itemsPerPage, sortedBusinesses.length)} of {sortedBusinesses.length} results
							</div>
							<div className="flex space-x-2">
								<button
									onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
									disabled={currentPage === 1}
									className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
								>
									Previous
								</button>
								
								{/* Page Numbers */}
								{Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => {
									// Show first, last, current, and adjacent pages
									if (
										page === 1 ||
										page === totalPages ||
										page === currentPage ||
										Math.abs(page - currentPage) <= 1
									) {
										return (
											<button
												key={page}
												onClick={() => setCurrentPage(page)}
												className={`px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
													page === currentPage
														? 'text-purple-600 bg-purple-50 border border-purple-300'
														: 'text-gray-700 bg-white border border-gray-300 hover:bg-gray-50'
												}`}
											>
												{page}
											</button>
										);
									} else if (
										(page === currentPage - 2 && currentPage > 3) ||
										(page === currentPage + 2 && currentPage < totalPages - 2)
									) {
										return (
											<span key={page} className="px-2 py-2 text-sm text-gray-500">
												...
											</span>
										);
									}
									return null;
								})}

								<button
									onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
									disabled={currentPage === totalPages}
									className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
								>
									Next
								</button>
							</div>
						</div>
					)}
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
		</RouteGuard>
	);
};

export default Businesses;

export const routePath = {
	path: "/app/businesses",
	Component: Businesses,
} as RouteObject;