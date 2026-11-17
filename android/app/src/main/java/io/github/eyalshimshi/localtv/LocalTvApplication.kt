package io.github.eyalshimshi.localtv

import android.app.Application

class LocalTvApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        CrashReporter.install(this)
        container = AppContainer(this)
    }
}
