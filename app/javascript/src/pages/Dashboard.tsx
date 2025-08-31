"use client";

import React, { useState, useEffect } from 'react';
import { RouteObject } from 'react-router';
import { Card } from 'flowbite-react';
import { 
	Users, 
	FileText, 
	BarChart3, 
	Globe,
	TrendingUp,
	AlertCircle,
	CheckCircle,
	Clock
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import DashboardLayout from '../layouts/DashboardLayout';
import ApplicationSidebar from '../components/Sidebar/Sidebar';

interface DashboardStats {
	users: {
		total: number;
		admin_count: number;
		business_count: number;
	};
	assessments: {
		total: number;
		active_count: number;
		inactive_count: number;
	};
	response_sessions: {
		total: number;
		completed: number;
		in_progress: number;
	};
	countries: {
		total: number;
		active: number;
	};
}

function Dashboard() {
	const { token } = useAuth();
	const [stats, setStats] = useState<DashboardStats | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		fetchDashboardStats();
	}, []);

	const fetchDashboardStats = async () => {
		if (!token) return;

		try {
			setLoading(true);
			setError(null);

			// Fetch multiple endpoints in parallel for dashboard stats
			const [usersResponse, assessmentsResponse, countriesResponse] = await Promise.all([
				fetch('/api/v1/admin/users', {
					headers: {
						'Authorization': `Bearer ${token}`,
						'Content-Type': 'application/json',
					},
				}),
				fetch('/api/v1/admin/assessments', {
					headers: {
						'Authorization': `Bearer ${token}`,
						'Content-Type': 'application/json',
					},
				}),
				fetch('/api/v1/admin/countries', {
					headers: {
						'Authorization': `Bearer ${token}`,
						'Content-Type': 'application/json',
					},
				})
			]);

			const [usersData, assessmentsData, countriesData] = await Promise.all([
				usersResponse.json(),
				assessmentsResponse.json(),
				countriesResponse.json()
			]);

			if (usersData.status === 'ok' && assessmentsData.status === 'ok' && countriesData.status === 'ok') {
				setStats({
					users: {
						total: usersData.data.total_count || 0,
						admin_count: usersData.data.admin_count || 0,
						business_count: usersData.data.business_count || 0,
					},
					assessments: {
						total: assessmentsData.data.total_count || 0,
						active_count: assessmentsData.data.active_count || 0,
						inactive_count: assessmentsData.data.inactive_count || 0,
					},
					response_sessions: {
						total: 0, // Will be implemented when we have this data
						completed: 0,
						in_progress: 0,
					},
					countries: {
						total: countriesData.data.countries?.length || 0,
						active: countriesData.data.countries?.filter((c: any) => c.active)?.length || 0,
					},
				});
			} else {
				throw new Error('Failed to fetch dashboard statistics');
			}
		} catch (err) {
			console.error('Dashboard fetch error:', err);
			setError(err instanceof Error ? err.message : 'Failed to load dashboard data');
		} finally {
			setLoading(false);
		}
	};

	if (loading) {
		return (
			<div className="flex items-center justify-center h-64">
				<div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
			</div>
		);
	}

	if (error) {
		return (
			<div className="flex items-center justify-center h-64">
				<div className="text-red-600 text-center">
					<AlertCircle className="w-8 h-8 mx-auto mb-2" />
					<p>{error}</p>
				</div>
			</div>
		);
	}

	return (
		<DashboardLayout>
			<DashboardLayout.Sidebar>
				<ApplicationSidebar />
			</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				<div className="space-y-6">
					{/* Header */}
					<div>
						<h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
						<p className="text-gray-600 mt-1">Overview of your assessment platform</p>
					</div>

			{/* Stats Grid */}
			<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
				{/* Users Card */}
				<Card className="border border-gray-200 shadow-none">
					<div className="flex items-center">
						<div className="p-3 rounded-full bg-blue-100">
							<Users className="w-6 h-6 text-blue-600" />
						</div>
						<div className="ml-4">
							<p className="text-sm font-medium text-gray-500">Total Users</p>
							<p className="text-2xl font-semibold text-gray-900">{stats?.users.total || 0}</p>
							<div className="flex text-xs text-gray-500 mt-1">
								<span>{stats?.users.admin_count || 0} admins</span>
								<span className="mx-1">•</span>
								<span>{stats?.users.business_count || 0} business</span>
							</div>
						</div>
					</div>
				</Card>

				{/* Assessments Card */}
				<Card className="border border-gray-200 shadow-none">
					<div className="flex items-center">
						<div className="p-3 rounded-full bg-green-100">
							<FileText className="w-6 h-6 text-green-600" />
						</div>
						<div className="ml-4">
							<p className="text-sm font-medium text-gray-500">Assessments</p>
							<p className="text-2xl font-semibold text-gray-900">{stats?.assessments.total || 0}</p>
							<div className="flex text-xs text-gray-500 mt-1">
								<span>{stats?.assessments.active_count || 0} active</span>
								<span className="mx-1">•</span>
								<span>{stats?.assessments.inactive_count || 0} inactive</span>
							</div>
						</div>
					</div>
				</Card>

				{/* Countries Card */}
				<Card className="border border-gray-200 shadow-none">
					<div className="flex items-center">
						<div className="p-3 rounded-full bg-purple-100">
							<Globe className="w-6 h-6 text-purple-600" />
						</div>
						<div className="ml-4">
							<p className="text-sm font-medium text-gray-500">Countries</p>
							<p className="text-2xl font-semibold text-gray-900">{stats?.countries.total || 0}</p>
							<div className="flex text-xs text-gray-500 mt-1">
								<span>{stats?.countries.active || 0} active</span>
							</div>
						</div>
					</div>
				</Card>

				{/* Performance Card */}
				<Card className="border border-gray-200 shadow-none">
					<div className="flex items-center">
						<div className="p-3 rounded-full bg-orange-100">
							<BarChart3 className="w-6 h-6 text-orange-600" />
						</div>
						<div className="ml-4">
							<p className="text-sm font-medium text-gray-500">Performance</p>
							<p className="text-2xl font-semibold text-gray-900">98.5%</p>
							<div className="flex text-xs text-gray-500 mt-1">
								<TrendingUp className="w-3 h-3 mr-1" />
								<span>System uptime</span>
							</div>
						</div>
					</div>
				</Card>
			</div>

			{/* Quick Actions */}
			<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				<Card className="border border-gray-200 shadow-none">
					<h3 className="text-lg font-medium text-gray-900 mb-4">Quick Actions</h3>
					<div className="space-y-3">
						<a 
							href="/app/assessments/new" 
							className="flex items-center px-3 py-2 text-sm font-medium text-blue-700 bg-blue-50 border border-blue-300 rounded-lg hover:bg-blue-100 transition-colors"
						>
							<FileText className="w-4 h-4 mr-2" />
							Create Assessment
						</a>
						<a 
							href="/app/users/invite" 
							className="flex items-center px-3 py-2 text-sm font-medium text-green-700 bg-green-50 border border-green-300 rounded-lg hover:bg-green-100 transition-colors"
						>
							<Users className="w-4 h-4 mr-2" />
							Invite User
						</a>
						<a 
							href="/app/assessments" 
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
						>
							<BarChart3 className="w-4 h-4 mr-2" />
							View All Assessments
						</a>
					</div>
				</Card>

				<Card className="border border-gray-200 shadow-none">
					<h3 className="text-lg font-medium text-gray-900 mb-4">Recent Activity</h3>
					<div className="space-y-3">
						<div className="flex items-center text-sm text-gray-600">
							<CheckCircle className="w-4 h-4 text-green-500 mr-2" />
							<span>New assessment created</span>
							<span className="ml-auto text-xs text-gray-400">2h ago</span>
						</div>
						<div className="flex items-center text-sm text-gray-600">
							<Users className="w-4 h-4 text-blue-500 mr-2" />
							<span>User invitation sent</span>
							<span className="ml-auto text-xs text-gray-400">1d ago</span>
						</div>
						<div className="flex items-center text-sm text-gray-600">
							<Clock className="w-4 h-4 text-orange-500 mr-2" />
							<span>Assessment completed</span>
							<span className="ml-auto text-xs text-gray-400">2d ago</span>
						</div>
					</div>
				</Card>

				<Card className="border border-gray-200 shadow-none">
					<h3 className="text-lg font-medium text-gray-900 mb-4">System Status</h3>
					<div className="space-y-3">
						<div className="flex items-center justify-between text-sm">
							<span className="text-gray-600">API Status</span>
							<span className="flex items-center text-green-600">
								<div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
								Online
							</span>
						</div>
						<div className="flex items-center justify-between text-sm">
							<span className="text-gray-600">Database</span>
							<span className="flex items-center text-green-600">
								<div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
								Connected
							</span>
						</div>
						<div className="flex items-center justify-between text-sm">
							<span className="text-gray-600">Last Backup</span>
							<span className="text-gray-500">12h ago</span>
						</div>
					</div>
				</Card>
			</div>
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app",
	Component: Dashboard,
} as RouteObject;