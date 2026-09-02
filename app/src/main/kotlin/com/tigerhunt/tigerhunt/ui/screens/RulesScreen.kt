package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RulesScreen(
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Rules & Himalayan Lore",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("rules_back_button")) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkBackground)
            )
        }
    ) { innerPadding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            RuleCard(
                icon = "🏔️",
                title = "Origins & History",
                body = "Bagh-Chal (बाघ चाल in Nepali) translates literally to 'Tigers moving'. Dating back over a thousand years, it was played in the courtyards of Patan and Kathmandu using etched stones and brass cast tokens. It simulates the natural ecology of the high hills, where royal Bengal tigers stalk domestic goat herds."
            )

            RuleCard(
                icon = "🎯",
                title = "Objective & Sides",
                body = "• Tigers (Bagh): The predator player commands 4 or 5 tigers. Win by capturing 5 goats.\n• Goats (Bakhri): The defender commands 20 goats. Win by surrounding and trapping all tigers so no tiger can make a valid step or leap."
            )

            RuleCard(
                icon = "📐",
                title = "Board & Topology",
                body = "The game is traditionally played on a 5x5 grid with full orthogonal lines, diagonal corner-to-corner lines, and an inner diamond. Some regional variations introduce triangular pyramid grids or 4-fan extensions for expanded tactical maneuverability."
            )

            RuleCard(
                icon = "⚡",
                title = "Master Goat Strategy",
                body = "1. Secure the center node (2,2) early.\n2. Keep goats connected in adjacent pairs or defensive triangles to prevent straight-line leaps.\n3. Push tigers toward the edges and corners where their mobility lines decrease from 8 down to 3."
            )

            RuleCard(
                icon = "🐅",
                title = "Master Tiger Strategy",
                body = "1. Avoid getting pushed to corners early.\n2. Create forks that threaten two separate goats along intersecting diagonals.\n3. Patiently sidestep to force goats to make vulnerable single-step departures."
            )
        }
    }
}

@Composable
private fun RuleCard(icon: String, title: String, body: String) {
    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, DarkSurfaceVariant, RoundedCornerShape(18.dp))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(icon, fontSize = 22.sp)
                Spacer(modifier = Modifier.width(10.dp))
                Text(
                    text = title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    color = HighlightGold
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = body,
                fontSize = 14.sp,
                color = GoatIvory,
                lineHeight = 21.sp
            )
        }
    }
}
