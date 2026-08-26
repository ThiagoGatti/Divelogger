import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../data/dive_site_model.dart';

class DiveSiteDetailsPage extends StatelessWidget {
  final DiveSiteModel site;

  const DiveSiteDetailsPage({
    super.key,
    required this.site,
  });

  @override
  Widget build(BuildContext context) {
    final location = [
      site.cidade,
      site.estado,
      site.pais,
    ]
        .where(
          (value) => value != null && value.isNotEmpty,
    )
        .join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: DiverrTheme.primary,
            foregroundColor: Colors.white,
            title: Text(
              site.nome,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DiverrTheme.primary,
                          DiverrTheme.ocean,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.scuba_diving,
                        size: 90,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Fotos do Dive Site',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.nome,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (location.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: DiverrTheme.primary,
                          size: 21,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Sobre o Dive Site',
                  ),

                  const SizedBox(height: 10),

                  Text(
                    site.descricao?.isNotEmpty == true
                        ? site.descricao!
                        : 'Nenhuma descrição foi adicionada '
                        'para este Dive Site.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: site.descricao?.isNotEmpty == true
                          ? Colors.grey.shade800
                          : Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Informações',
                  ),

                  const SizedBox(height: 14),

                  _buildInfoCard(),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Localização',
                  ),

                  const SizedBox(height: 14),

                  _buildLocationCard(),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Fotos',
                  ),

                  const SizedBox(height: 14),

                  _buildPhotosPlaceholder(),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Mergulhos neste Dive Site',
                  ),

                  const SizedBox(height: 14),

                  _buildDivesPlaceholder(),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Futuramente:
                        // abrir tela para registrar um mergulho
                        // neste Dive Site.
                      },
                      icon: const Icon(
                        Icons.scuba_diving,
                      ),
                      label: const Text(
                        'Registrar mergulho aqui',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DiverrTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: DiverrTheme.dark,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.category_outlined,
                  label: 'Tipo',
                  value: _tipoLabel(site.tipo),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _infoItem(
                  icon: Icons.arrow_downward,
                  label: 'Profundidade',
                  value: site.profundidadeMaxima != null
                      ? '${site.profundidadeMaxima} m'
                      : 'Não informado',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.north,
                  label: 'Latitude',
                  value: site.latitude.toStringAsFixed(6),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _infoItem(
                  icon: Icons.east,
                  label: 'Longitude',
                  value: site.longitude.toStringAsFixed(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: DiverrTheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DiverrTheme.ocean.withOpacity(.85),
            DiverrTheme.primary,
          ],
        ),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 64,
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${site.latitude.toStringAsFixed(6)}, '
                    '${site.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 42,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          Text(
            'Nenhuma foto adicionada ainda',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'As fotos dos mergulhadores aparecerão aqui.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivesPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.scuba_diving,
            size: 38,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          Text(
            'Ainda não há mergulhos registrados',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Seja o primeiro a registrar um mergulho neste local.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _tipoLabel(String? tipo) {
    switch (tipo) {
      case 'COSTEIRO':
        return 'Costeiro';

      case 'NAUFRAGIO':
        return 'Naufrágio';

      case 'RECIFE':
        return 'Recife';

      case 'CAVERNA':
        return 'Caverna';

      case 'PAREDE':
        return 'Parede';

      case 'PEDREIRA':
        return 'Pedreira';

      case 'LAGO':
        return 'Lago';

      case 'RIO':
        return 'Rio';

      case 'OUTRO':
        return 'Outro';

      default:
        return 'Não informado';
    }
  }
}