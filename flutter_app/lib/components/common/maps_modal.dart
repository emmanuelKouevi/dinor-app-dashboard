import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MapsModal extends StatefulWidget {
  final String location;

  const MapsModal({
    super.key,
    required this.location,
  });

  @override
  State<MapsModal> createState() => _MapsModalState();
}

class _MapsModalState extends State<MapsModal> {
  InAppWebViewController? _webViewController;
  bool isLoading = true;
  String? errorMessage;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
  }

  String _generateMapHtml() {
    final encodedLocation = Uri.encodeComponent(widget.location);
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 0;
                height: 100vh;
                overflow: hidden;
                font-family: 'OpenSans', sans-serif;
            }
            .map-container {
                width: 100%;
                height: 100%;
                position: relative;
            }
            iframe {
                width: 100%;
                height: 100%;
                border: none;
            }
            .loading {
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                color: #718096;
                font-size: 14px;
            }
            .error {
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                height: 100vh;
                color: #718096;
                text-align: center;
                padding: 20px;
            }
        </style>
    </head>
    <body>
        <div class="map-container">
            <iframe 
                id="mapFrame"
                src="https://maps.google.com/maps?q=$encodedLocation&output=embed"
                allowfullscreen=""
                loading="lazy"
                referrerpolicy="no-referrer-when-downgrade"
                sandbox="allow-scripts allow-same-origin allow-popups">
            </iframe>
        </div>
        
        <script>
            // Gérer les erreurs de chargement
            var iframe = document.getElementById('mapFrame');
            var timeout = setTimeout(function() {
                // Si l'iframe ne répond pas après 10 secondes, afficher un fallback
                if (!iframe.contentDocument || iframe.contentDocument.body.innerHTML === '') {
                    document.body.innerHTML = '<div class="error"><div>📍</div><div>Carte non disponible</div><div style="font-size: 12px; margin-top: 10px;">$encodedLocation</div></div>';
                }
            }, 10000);
            
            iframe.onload = function() {
                clearTimeout(timeout);
                console.log('Carte chargée avec succès');
            };
            
            iframe.onerror = function() {
                clearTimeout(timeout);
                document.body.innerHTML = '<div class="error"><div>📍</div><div>Erreur de chargement</div><div style="font-size: 12px; margin-top: 10px;">${widget.location}</div></div>';
            };
        </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header avec titre et bouton fermer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4D03F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: Color(0xFFF4D03F),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Localisation',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Bouton fermer
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Color(0xFF718096),
                    ),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),
            
            // WebView avec Google Maps
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    InAppWebView(
                      initialData: InAppWebViewInitialData(
                        data: _generateMapHtml(),
                        baseUrl: WebUri('https://maps.google.com'),
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        useHybridComposition: true,
                        allowFileAccess: true,
                        allowContentAccess: true,
                        transparentBackground: true,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        if (mounted) {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                        }
                      },
                      onLoadStop: (controller, url) {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                      onProgressChanged: (controller, progress) {
                        if (mounted) {
                          setState(() {
                            _progress = progress / 100;
                          });
                        }
                      },
                      onReceivedError: (controller, request, error) {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                            errorMessage = 'Erreur de chargement de la carte';
                          });
                        }
                      },
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      },
                    ),
                    
                    // Indicateur de chargement
                    if (isLoading)
                      Container(
                        color: Colors.white,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFFF4D03F),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Chargement de la carte...',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 14,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Message d'erreur
                    if (errorMessage != null)
                      Container(
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 48,
                                color: Color(0xFF718096),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 16,
                                  color: Color(0xFF718096),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    errorMessage = null;
                                    isLoading = true;
                                  });
                                  _webViewController?.loadData(
                                    data: _generateMapHtml(),
                                    baseUrl: WebUri('https://maps.google.com'),
                                  );
                                },
                                icon: const Icon(
                                  LucideIcons.refreshCw,
                                  size: 16,
                                ),
                                label: const Text('Réessayer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF4D03F),
                                  foregroundColor: const Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fonction utilitaire pour afficher la modal
void showMapsModal(BuildContext context, String location) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => MapsModal(location: location),
  );
}