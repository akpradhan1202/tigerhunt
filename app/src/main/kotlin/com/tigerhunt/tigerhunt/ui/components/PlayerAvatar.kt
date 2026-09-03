package com.tigerhunt.tigerhunt.ui.components

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.ui.theme.DarkSurfaceVariant
import com.tigerhunt.tigerhunt.ui.theme.HighlightGold
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

@Composable
fun PlayerAvatar(
    avatarId: String,
    modifier: Modifier = Modifier,
    customAvatarUri: String? = null,
    size: Dp = 44.dp,
    fontSize: TextUnit = 22.sp,
    borderColor: Color = HighlightGold,
    borderWidth: Dp = 1.5.dp,
    backgroundColor: Color = DarkSurfaceVariant,
    shape: Shape = CircleShape,
    contentDescription: String? = "Player Avatar"
) {
    val context = LocalContext.current

    val bitmapState by produceState<Bitmap?>(initialValue = null, key1 = customAvatarUri) {
        if (!customAvatarUri.isNullOrBlank()) {
            value = withContext(Dispatchers.IO) {
                try {
                    when {
                        customAvatarUri.startsWith("content://") || customAvatarUri.startsWith("file://") -> {
                            val uri = Uri.parse(customAvatarUri)
                            context.contentResolver.openInputStream(uri)?.use { stream ->
                                BitmapFactory.decodeStream(stream)
                            }
                        }
                        customAvatarUri.startsWith("/") -> {
                            val file = File(customAvatarUri)
                            if (file.exists()) {
                                BitmapFactory.decodeFile(file.absolutePath)
                            } else null
                        }
                        else -> {
                            // Check if it's a relative file path in context.filesDir
                            val file = File(context.filesDir, customAvatarUri)
                            if (file.exists()) {
                                BitmapFactory.decodeFile(file.absolutePath)
                            } else null
                        }
                    }
                } catch (_: Exception) {
                    null
                }
            }
        } else {
            value = null
        }
    }

    Box(
        modifier = modifier
            .size(size)
            .clip(shape)
            .background(backgroundColor)
            .then(
                if (borderWidth > 0.dp) {
                    Modifier.border(borderWidth, borderColor, shape)
                } else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        val loadedBitmap = bitmapState
        if (loadedBitmap != null) {
            Image(
                bitmap = loadedBitmap.asImageBitmap(),
                contentDescription = contentDescription,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            Text(
                text = avatarId.ifBlank { "🐅" },
                fontSize = fontSize,
                textAlign = TextAlign.Center
            )
        }
    }
}
