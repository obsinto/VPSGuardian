#!/usr/bin/env node
/**
 * Script: backup-website-playwright.js
 * Propósito: Baixar páginas Next.js/React com conteúdo renderizado
 * Uso: node backup-website-playwright.js
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// URLs para fazer backup
const pages = [
  {
    url: 'https://envix.shadowarcanist.com/coolify/tutorials/migrate-apps-different-host/',
    name: 'migrate-apps-different-host'
  },
  {
    url: 'https://envix.shadowarcanist.com/coolify/tutorials/aws-s3-backup-setup/',
    name: 'aws-s3-backup-setup'
  },
  {
    url: 'https://envix.shadowarcanist.com/coolify/tutorials/',
    name: 'tutorials-index'
  }
];

// Diretório de saída
const OUTPUT_DIR = path.join(process.env.HOME, 'Backups', 'coolify-docs');

(async () => {
  // Criar diretório se não existir
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  console.log('🚀 Iniciando backup de páginas...\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });

  for (const page of pages) {
    console.log(`📄 Processando: ${page.name}`);
    console.log(`   URL: ${page.url}`);

    const browserPage = await context.newPage();

    try {
      // Navegar e aguardar carregamento completo
      await browserPage.goto(page.url, {
        waitUntil: 'networkidle',
        timeout: 30000
      });

      // Aguardar renderização do React/Next.js
      await browserPage.waitForTimeout(2000);

      // Salvar HTML renderizado
      const html = await browserPage.content();
      const htmlPath = path.join(OUTPUT_DIR, `${page.name}.html`);
      fs.writeFileSync(htmlPath, html, 'utf-8');
      console.log(`   ✅ HTML salvo: ${htmlPath}`);

      // Salvar screenshot
      const screenshotPath = path.join(OUTPUT_DIR, `${page.name}.png`);
      await browserPage.screenshot({
        path: screenshotPath,
        fullPage: true
      });
      console.log(`   ✅ Screenshot salvo: ${screenshotPath}`);

      // Salvar PDF
      const pdfPath = path.join(OUTPUT_DIR, `${page.name}.pdf`);
      await browserPage.pdf({
        path: pdfPath,
        format: 'A4',
        printBackground: true,
        margin: {
          top: '20px',
          right: '20px',
          bottom: '20px',
          left: '20px'
        }
      });
      console.log(`   ✅ PDF salvo: ${pdfPath}\n`);

    } catch (error) {
      console.error(`   ❌ Erro ao processar ${page.name}:`, error.message);
    } finally {
      await browserPage.close();
    }
  }

  await browser.close();

  console.log('\n🎉 Backup concluído!');
  console.log(`📁 Arquivos salvos em: ${OUTPUT_DIR}`);
  console.log('\nArquivos criados para cada página:');
  console.log('  • .html - HTML renderizado (pode não funcionar offline)');
  console.log('  • .pdf  - PDF completo (melhor para arquivo)');
  console.log('  • .png  - Screenshot da página inteira');
})();
