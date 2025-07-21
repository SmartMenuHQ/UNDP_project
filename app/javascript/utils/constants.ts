// App constants
export const APP_NAME = 'Questionnaire CMS'
export const APP_VERSION = '1.0.0'

// Theme colors
export const COLORS = {
  primary: '#2563eb', // blue-600
  secondary: '#64748b', // slate-500
  success: '#059669', // emerald-600
  warning: '#d97706', // amber-600
  error: '#dc2626', // red-600
} as const

// API configuration
export const API_CONFIG = {
  baseURL: '/api/v1',
  timeout: 10000,
} as const

// Routes
export const ROUTES = {
  dashboard: '/app/dashboard',
  assessments: '/app/assessments',
  new_assessment: '/app/assessments/new',
} as const
