package co.edu.escuelaing.secureapp.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

/**
 * Configuración de CORS para la aplicación.
 * Permite el acceso desde diferentes orígenes y define los métodos HTTP habilitados.
 */
@Configuration
public class CorsConfig {

    /**
     * Configura las reglas de CORS permitiendo el acceso desde cualquier origen.
     * Se habilitan los métodos HTTP más comunes y se aceptan todos los encabezados.
     *
     * @return Registro donde se establecen las reglas de CORS.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("http://localhost:8000", "http://127.0.0.1:8000"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
