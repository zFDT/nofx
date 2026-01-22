import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { useLanguage } from '../contexts/LanguageContext'

interface VersionInfo {
  version: string
  commit: string
  branch: string
  buildDate: string
  goVersion: string
  description?: string
  features?: string[]
}

/**
 * 版本信息页面
 * 显示后端版本、构建信息等
 */
export function VersionPage() {
  const { language } = useLanguage()
  const [versionInfo, setVersionInfo] = useState<VersionInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchVersionInfo()
  }, [])

  const fetchVersionInfo = async () => {
    try {
      setLoading(true)
      const response = await fetch('/api/version')
      if (!response.ok) {
        throw new Error('Failed to fetch version info')
      }
      const data = await response.json()
      setVersionInfo(data)
      setError(null)
    } catch (err) {
      console.error('Error fetching version:', err)
      setError(language === 'zh' ? '无法获取版本信息' : 'Failed to fetch version info')
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateString: string) => {
    if (!dateString) return language === 'zh' ? '未知' : 'Unknown'
    try {
      const date = new Date(dateString)
      return date.toLocaleString(language === 'zh' ? 'zh-CN' : 'en-US', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
      })
    } catch {
      return dateString
    }
  }

  return (
    <div
      className="min-h-screen py-8"
      style={{
        background: '#0B0E11',
        color: '#EAECEF',
      }}
    >
      <div className="max-w-4xl mx-auto px-4">
        {/* 标题 */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="text-center mb-8"
        >
          <h1 className="text-4xl font-bold mb-2" style={{ color: '#F0B90B' }}>
            {language === 'zh' ? '🔖 版本信息' : '🔖 Version Info'}
          </h1>
          <p className="text-lg" style={{ color: '#848E9C' }}>
            {language === 'zh'
              ? 'NOFX AI 交易系统版本详情'
              : 'NOFX AI Trading System Version Details'}
          </p>
        </motion.div>

        {/* 加载状态 */}
        {loading && (
          <div className="text-center py-12">
            <div
              className="inline-block animate-spin rounded-full h-12 w-12 border-b-2"
              style={{ borderColor: '#F0B90B' }}
            ></div>
            <p className="mt-4" style={{ color: '#848E9C' }}>
              {language === 'zh' ? '加载中...' : 'Loading...'}
            </p>
          </div>
        )}

        {/* 错误状态 */}
        {error && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="p-6 rounded-lg text-center"
            style={{
              background: '#2B1616',
              border: '1px solid #F6465D',
            }}
          >
            <p style={{ color: '#F6465D' }}>{error}</p>
            <button
              onClick={fetchVersionInfo}
              className="mt-4 px-6 py-2 rounded font-semibold transition-all hover:scale-105"
              style={{
                background: '#F0B90B',
                color: '#0B0E11',
              }}
            >
              {language === 'zh' ? '重试' : 'Retry'}
            </button>
          </motion.div>
        )}

        {/* 版本信息卡片 */}
        {versionInfo && !loading && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="space-y-6"
          >
            {/* 主要信息卡片 */}
            <div
              className="p-8 rounded-lg"
              style={{
                background: '#1E2329',
                border: '1px solid #2B3139',
              }}
            >
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* 版本号 */}
                <div>
                  <p className="text-sm mb-1" style={{ color: '#848E9C' }}>
                    {language === 'zh' ? '版本号' : 'Version'}
                  </p>
                  <p className="text-2xl font-bold" style={{ color: '#F0B90B' }}>
                    {versionInfo.version || 'dev'}
                  </p>
                </div>

                {/* 构建日期 */}
                <div>
                  <p className="text-sm mb-1" style={{ color: '#848E9C' }}>
                    {language === 'zh' ? '构建日期' : 'Build Date'}
                  </p>
                  <p className="text-lg font-semibold" style={{ color: '#EAECEF' }}>
                    {formatDate(versionInfo.buildDate)}
                  </p>
                </div>

                {/* Git 提交 */}
                <div>
                  <p className="text-sm mb-1" style={{ color: '#848E9C' }}>
                    {language === 'zh' ? 'Git 提交' : 'Git Commit'}
                  </p>
                  <p
                    className="text-sm font-mono px-2 py-1 rounded inline-block"
                    style={{
                      background: '#0B0E11',
                      color: '#F0B90B',
                    }}
                  >
                    {versionInfo.commit || (language === 'zh' ? '未知' : 'N/A')}
                  </p>
                </div>

                {/* Git 分支 */}
                <div>
                  <p className="text-sm mb-1" style={{ color: '#848E9C' }}>
                    {language === 'zh' ? 'Git 分支' : 'Git Branch'}
                  </p>
                  <p className="text-lg font-semibold" style={{ color: '#EAECEF' }}>
                    {versionInfo.branch || 'main'}
                  </p>
                </div>

                {/* Go 版本 */}
                <div className="md:col-span-2">
                  <p className="text-sm mb-1" style={{ color: '#848E9C' }}>
                    {language === 'zh' ? 'Go 版本' : 'Go Version'}
                  </p>
                  <p className="text-lg font-semibold" style={{ color: '#EAECEF' }}>
                    {versionInfo.goVersion || 'Unknown'}
                  </p>
                </div>
              </div>
            </div>

            {/* 描述信息 */}
            {versionInfo.description && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.3 }}
                className="p-6 rounded-lg"
                style={{
                  background: '#1E2329',
                  border: '1px solid #2B3139',
                }}
              >
                <h3 className="text-lg font-semibold mb-3" style={{ color: '#F0B90B' }}>
                  {language === 'zh' ? '📝 版本描述' : '📝 Description'}
                </h3>
                <p style={{ color: '#EAECEF' }}>{versionInfo.description}</p>
              </motion.div>
            )}

            {/* 功能列表 */}
            {versionInfo.features && versionInfo.features.length > 0 && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.4 }}
                className="p-6 rounded-lg"
                style={{
                  background: '#1E2329',
                  border: '1px solid #2B3139',
                }}
              >
                <h3 className="text-lg font-semibold mb-4" style={{ color: '#F0B90B' }}>
                  {language === 'zh' ? '✨ 功能特性' : '✨ Features'}
                </h3>
                <ul className="space-y-2">
                  {versionInfo.features.map((feature, index) => (
                    <motion.li
                      key={index}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ duration: 0.3, delay: 0.5 + index * 0.1 }}
                      className="flex items-start gap-3"
                    >
                      <span style={{ color: '#0ECB81', fontSize: '1.2em' }}>✓</span>
                      <span style={{ color: '#EAECEF' }}>{feature}</span>
                    </motion.li>
                  ))}
                </ul>
              </motion.div>
            )}

            {/* 系统信息 */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.5 }}
              className="p-6 rounded-lg text-center"
              style={{
                background: '#1E2329',
                border: '1px solid #2B3139',
              }}
            >
              <p className="text-sm" style={{ color: '#848E9C' }}>
                {language === 'zh'
                  ? '🚀 NOFX - AI 驱动的智能交易系统'
                  : '🚀 NOFX - AI-Powered Trading System'}
              </p>
              <p className="text-xs mt-2" style={{ color: '#474D57' }}>
                {language === 'zh'
                  ? '通过版本号确保您运行的是最新代码'
                  : 'Verify you are running the latest code via version number'}
              </p>
            </motion.div>

            {/* 刷新按钮 */}
            <div className="text-center">
              <button
                onClick={fetchVersionInfo}
                className="px-8 py-3 rounded-lg font-semibold transition-all hover:scale-105 inline-flex items-center gap-2"
                style={{
                  background: 'linear-gradient(135deg, #F0B90B 0%, #FCD535 100%)',
                  color: '#0B0E11',
                }}
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2" />
                </svg>
                {language === 'zh' ? '刷新版本信息' : 'Refresh Version Info'}
              </button>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  )
}
