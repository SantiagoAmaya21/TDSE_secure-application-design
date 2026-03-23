# Final Deployment Commands - AWS Academy
# =======================================

## 🦆 Tu Configuración DuckDNS
- **Subdominio:** `tdse-secure-app.duckdns.org`
- **Frontend URL:** `https://tdse-secure-app.duckdns.org`
- **Backend API:** `https://tdse-secure-app.duckdns.org:8443`

## 📋 VALORES QUE NECESITAS:

### 1. DuckDNS Token
```
TU_DUCKDNS_TOKEN = "tu-token-aqui"
```
**¿Dónde obtenerlo?** 
- Ve a: https://www.duckdns.org/
- Login y busca tu subdominio "tdse-secure-app"
- Copia el token que aparece

### 2. SSH Key Pair
```
TU_KEY_PAIR = "nombre-de-tu-key.pem"
```
**¿Dónde obtenerlo?**
- En AWS Academy console
- EC2 → Key Pairs → Create/Import

## 🚀 COMANDOS FINALES:

### Paso 1: Crear EC2 Instances
```bash
# Instance 1: Apache Web Server
# - Amazon Linux 2023
# - Security Group: HTTP(80), HTTPS(443), SSH(22)
# - Tag: "Apache-Web-Server"

# Instance 2: Spring Boot Application
# - Amazon Linux 2023  
# - Security Group: Custom TCP(8443), SSH(22)
# - Tag: "Spring-Boot-App"
```

### Paso 2: Deploy Apache Server
```bash
# Reemplaza <APACHE_PUBLIC_IP> con la IP real
ssh -i TU_KEY_PAIR.pem ec2-user@<APACHE_PUBLIC_IP>

# Ejecutar deployment
git clone https://github.com/SantiagoAmaya21/TDSE_secure-application-design.git
cd TDSE_secure-application-design
chmod +x scripts/aws-deploy-apache-duckdns.sh
./scripts/aws-deploy-apache-duckdns.sh tdse-secure-app TU_DUCKDNS_TOKEN
```

### Paso 3: Deploy Spring Boot Server  
```bash
# Reemplaza <SPRING_PUBLIC_IP> con la IP real
ssh -i TU_KEY_PAIR.pem ec2-user@<SPRING_PUBLIC_IP>

# Ejecutar deployment
git clone https://github.com/SantiagoAmaya21/TDSE_secure-application-design.git
cd TDSE_secure-application-design
chmod +x scripts/aws-deploy-spring.sh
chmod +x scripts/setup-ssl-spring-duckdns.sh
./scripts/aws-deploy-spring.sh
./scripts/setup-ssl-spring-duckdns.sh tdse-secure-app.duckdns.org TU_DUCKDNS_TOKEN
```

## ✅ VERIFICACIÓN FINAL:

### Test Commands
```bash
# Test Apache (desde cualquier lugar)
curl -I https://tdse-secure-app.duckdns.org

# Test Spring Boot (desde Spring instance)
curl -k https://localhost:8443/auth/register

# Test completo en browser
# Abrir: https://tdse-secure-app.duckdns.org
```

### Screenshots Requeridas
1. **DuckDNS Dashboard** - Mostrar subdominio tdse-secure-app
2. **AWS EC2 Console** - Dos instancias corriendo
3. **Apache HTTPS** - `https://tdse-secure-app.duckdns.org` con padlock
4. **Spring Boot HTTPS** - API respondiendo por 8443
5. **Application Login** - Pantalla de registro/login
6. **Application Dashboard** - Después de login exitoso
7. **Certificate Details** - Let's Encrypt válido

## 🔧 COMANDOS DE TROUBLESHOOTING:

### DuckDNS Issues
```bash
# Actualizar manualmente
curl "https://www.duckdns.org/update?domains=tdse-secure-app&token=TU_DUCKDNS_TOKEN&ip=$(curl -s ifconfig.me)"

# Verificar DNS
nslookup tdse-secure-app.duckdns.org
```

### SSL Certificate Issues
```bash
# Apache
sudo certbot certificates
sudo certbot renew

# Spring Boot
sudo systemctl restart secure-app
sudo journalctl -u secure-app -f
```

### Service Issues
```bash
# Apache
sudo systemctl status httpd
sudo tail -f /var/log/httpd/error_log

# Spring Boot
sudo systemctl status secure-app
sudo journalctl -u secure-app -n 50
```

## 📱 CHECKLIST FINAL ANTES DE PRESENTAR:

- [ ] DuckDNS configurado con tdse-secure-app.duckdns.org
- [ ] Dos instancias EC2 creadas y corriendo
- [ ] Apache funcionando por HTTPS
- [ ] Spring Boot funcionando por HTTPS
- [ ] Aplicación completa funcional
- [ ] Todos los screenshots capturados
- [ ] Video demostrativo grabado (5-10 min)

## 🎯 URLs Finales:
- **Frontend:** https://tdse-secure-app.duckdns.org
- **Backend API:** https://tdse-secure-app.duckdns.org:8443
- **Login:** https://tdse-secure-app.duckdns.org (register/login)
- **API Test:** https://tdse-secure-app.duckdns.org:8443/auth/register

---

**LISTO PARA AWS ACADEMY!** 🚀
