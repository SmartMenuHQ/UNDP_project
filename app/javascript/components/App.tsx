import { APP_NAME, APP_VERSION } from '@/utils/constants'

const App = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50">


      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            Welcome to {APP_NAME}
          </h2>
          <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
            Create, manage, and deploy dynamic questionnaires and assessments with ease.
            Built with React, TypeScript, and Rails for maximum flexibility and performance.
          </p>
        </div>

      </main>

      {/* Footer */}
      <footer className="bg-gray-800 text-gray-300 py-8 mt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p>&copy; 2024 {APP_NAME} v{APP_VERSION}. Built with React + TypeScript + Rails.</p>
        </div>
      </footer>
    </div>
  )
}

export default App
