package com.tigerhunt.tigerhunt.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.tigerhunt.tigerhunt.ui.theme.AmberTiger
import com.tigerhunt.tigerhunt.ui.theme.DarkSurfaceVariant
import com.tigerhunt.tigerhunt.ui.theme.HighlightGold

@Composable
fun GameControls(
    onUndoClick: () -> Unit,
    onHintClick: () -> Unit,
    onRestartClick: () -> Unit,
    onSettingsClick: () -> Unit,
    isSoundEnabled: Boolean,
    onSoundToggle: () -> Unit,
    canUndo: Boolean,
    modifier: Modifier = Modifier
) {
    Surface(
        color = DarkSurfaceVariant,
        shape = RoundedCornerShape(24.dp),
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = onUndoClick,
                enabled = canUndo,
                modifier = Modifier.testTag("undo_button")
            ) {
                Icon(
                    imageVector = Icons.Default.Undo,
                    contentDescription = "Undo Move",
                    tint = if (canUndo) Color.White else Color.DarkGray
                )
            }

            IconButton(
                onClick = onHintClick,
                modifier = Modifier.testTag("hint_button")
            ) {
                Icon(
                    imageVector = Icons.Default.Lightbulb,
                    contentDescription = "Tactical Hint",
                    tint = HighlightGold
                )
            }

            IconButton(
                onClick = onRestartClick,
                modifier = Modifier.testTag("restart_button")
            ) {
                Icon(
                    imageVector = Icons.Default.Refresh,
                    contentDescription = "Restart Match",
                    tint = AmberTiger
                )
            }

            IconButton(
                onClick = onSoundToggle,
                modifier = Modifier.testTag("sound_toggle")
            ) {
                Icon(
                    imageVector = if (isSoundEnabled) Icons.Default.VolumeUp else Icons.Default.VolumeOff,
                    contentDescription = "Sound Toggle",
                    tint = Color.White
                )
            }

            IconButton(
                onClick = onSettingsClick,
                modifier = Modifier.testTag("settings_button")
            ) {
                Icon(
                    imageVector = Icons.Default.Settings,
                    contentDescription = "Match Settings",
                    tint = Color.LightGray
                )
            }
        }
    }
}
