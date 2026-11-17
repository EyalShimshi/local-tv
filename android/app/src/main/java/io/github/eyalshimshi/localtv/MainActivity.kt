package io.github.eyalshimshi.localtv

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.res.Configuration
import android.media.AudioManager
import android.os.Bundle
import android.util.Rational
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import io.github.eyalshimshi.localtv.ui.LocalTvApp
import io.github.eyalshimshi.localtv.ui.LocalTvViewModel
import io.github.eyalshimshi.localtv.ui.theme.LocalTvTheme
import io.github.eyalshimshi.localtv.ui.theme.isDarkTheme
import kotlinx.coroutines.flow.MutableStateFlow

class MainActivity : AppCompatActivity() {

    private val viewModel: LocalTvViewModel by viewModels()
    private val inPictureInPicture = MutableStateFlow(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        // The volume keys change the media volume even while every channel is muted.
        volumeControlStream = AudioManager.STREAM_MUSIC
        if (savedInstanceState == null) handleIntent(intent)

        setContent {
            val settings by viewModel.settings.collectAsStateWithLifecycle()
            val pip by inPictureInPicture.collectAsStateWithLifecycle()
            val current = settings
            if (current != null) {
                LocalTvTheme(current) {
                    val dark = isDarkTheme(current)
                    DisposableEffect(dark) {
                        val transparent = android.graphics.Color.TRANSPARENT
                        val style = if (dark) {
                            SystemBarStyle.dark(transparent)
                        } else {
                            SystemBarStyle.light(transparent, transparent)
                        }
                        enableEdgeToEdge(statusBarStyle = style, navigationBarStyle = style)
                        onDispose { }
                    }
                    val watch by viewModel.watch.collectAsStateWithLifecycle()
                    val pipChannel = watch.fullscreen ?: watch.spotlight
                    val canEnterPip = current.pictureInPicture && pipChannel != null && pipChannel.isStream
                    LaunchedEffect(canEnterPip) { updatePictureInPicture(canEnterPip) }
                    Surface(color = MaterialTheme.colorScheme.background) {
                        LocalTvApp(viewModel = viewModel, settings = current, inPictureInPicture = pip)
                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        viewModel.onScreenStarted()
    }

    override fun onStop() {
        // Picture-in-picture keeps the activity started; a recreated screen comes right back.
        if (!isChangingConfigurations) viewModel.onScreenStopped()
        super.onStop()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        inPictureInPicture.value = isInPictureInPictureMode
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    /** localtv://play?url=<stream>&name=<title> previews a stream in the spotlight. */
    private fun handleIntent(intent: Intent?) {
        val data = intent?.data ?: return
        if (data.scheme != "localtv" || data.host != "play") return
        val url = data.getQueryParameter("url") ?: return
        viewModel.openPreview(url, data.getQueryParameter("name"))
    }

    /** Leaving the app with a channel in the spotlight keeps it playing in a small window. */
    private fun updatePictureInPicture(enabled: Boolean) {
        runCatching {
            setPictureInPictureParams(
                PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(16, 9))
                    .setAutoEnterEnabled(enabled)
                    .setSeamlessResizeEnabled(enabled)
                    .build(),
            )
        }
    }
}
