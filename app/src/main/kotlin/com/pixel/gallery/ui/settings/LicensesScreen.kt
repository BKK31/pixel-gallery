package com.pixel.gallery.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.clickable
import com.pixel.gallery.ui.theme.EmphasizedTypography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LicensesScreen(onBack: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        "Open Source Licenses",
                        style = EmphasizedTypography.TitleLarge
                    ) 
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 20.dp, vertical = 24.dp)
        ) {
            item {
                Text(
                    text = "SPECIAL ATTRIBUTION: AVES",
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Pixel Gallery is built with inspiration and core components from the Aves project.\n\n" +
                           "BSD 3-Clause License\n\n" +
                           "Copyright (c) 2020, Thibault Deckers\n" +
                           "All rights reserved.\n\n" +
                           "Redistribution and use in source and binary forms, with or without\n" +
                           "modification, are permitted provided that the following conditions are met:\n\n" +
                           "1. Redistributions of source code must retain the above copyright notice, this\n" +
                           "   list of conditions and the following disclaimer.\n\n" +
                           "2. Redistributions in binary form must reproduce the above copyright notice,\n" +
                           "   this list of conditions and the following disclaimer in the documentation\n" +
                           "   and/or other materials provided with the distribution.\n\n" +
                           "3. Neither the name of the copyright holder nor the names of its\n" +
                           "   contributors may be used to endorse or promote products derived from\n" +
                           "   this software without specific prior written permission.\n\n" +
                           "THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"\n" +
                           "AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\n" +
                           "IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\n" +
                           "DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE\n" +
                           "FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL\n" +
                           "DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR\n" +
                           "SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER\n" +
                           "CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\n" +
                           "OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\n" +
                           "OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.",
                    style = MaterialTheme.typography.bodySmall,
                    lineHeight = androidx.compose.ui.unit.TextUnit.Unspecified
                )
            }
        }
    }
}
