# Music Manager — GitHub Pages (V4)

Esta é a mesma base visual e funcional do **Music Manager V4**, preparada para publicação no **GitHub Pages**. A mudança principal é a estrutura de hospedagem: o `index.html` continua sendo o site V4, e foram adicionados `manifest.webmanifest`, `sw.js` e `icon.svg` para funcionar melhor em dispositivos móveis e permitir instalação como PWA em navegadores compatíveis.

## Publicar

1. Crie um repositório no GitHub, por exemplo `music-manager`.
2. Envie `index.html`, `manifest.webmanifest`, `sw.js` e `icon.svg` para a raiz do repositório.
3. Abra **Settings → Pages**.
4. Em **Build and deployment**, escolha **Deploy from a branch**.
5. Branch: `main` e pasta: `/ (root)`.
6. Salve e aguarde o GitHub publicar.

O endereço será parecido com:
`https://SEU-USUARIO.github.io/music-manager/`

## Importante

- O cadastro/login da V4 é local (localStorage), então não é uma conta online real.
- Os arquivos de áudio adicionados pelo botão são locais ao dispositivo/navegador e não ficam armazenados no GitHub.
- Para transformar o projeto em uma plataforma de streaming real, com contas online, playlists sincronizadas e upload permanente, será necessário um backend/banco de dados e armazenamento.
- O projeto inclui a marca d'água **Duster-x Productions** conforme a V4.
