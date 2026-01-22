import { useLanguage } from '../contexts/LanguageContext'
import { CompetitionPage } from './CompetitionPage'

export function DataPage() {
  const { language } = useLanguage()

  return (
    <div className="w-full min-h-[calc(100vh-64px)] p-6" style={{ background: '#0B0E11' }}>
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-6" style={{ color: '#EAECEF' }}>
          {language === 'zh' ? '📈 数据中心' : '📈 Data Center'}
        </h1>
        <CompetitionPage />
      </div>
    </div>
  )
}
