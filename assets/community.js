/* Shared community features. Supabase is the source of truth; no local vote cache. */
let authSubmitting = false, authPreviousFocus = null;
function setAuthBusy(busy) {
    authSubmitting = busy;
    document.querySelectorAll('#userAuthModal form button').forEach(b => { b.disabled = busy; });
}
let editingArticleId = null, editingBodyText = '', editingBodyHTML = '';
let commentsRequest = 0, communityRequest = 0, refreshInFlight = false;
let rankingPublished = null, rankingDraft = Array(10).fill(''), rankingPaused = false;
let rankingEditingBase = null, rankingBusy = false;
const votePending = new Set();
const commentRows = new Map();

function node(tag, text, className) {
    const el = document.createElement(tag);
    if (text != null) el.textContent = text;
    if (className) el.className = className;
    return el;
}
function notifyCommunity(text, error = false) {
    let el = document.getElementById('communityNotice');
    if (!el) {
        el = node('div', '', 'rcm-notice'); el.id = 'communityNotice';
        el.setAttribute('role', 'status'); el.setAttribute('aria-live', 'polite');
        document.body.append(el);
    }
    el.textContent = text; el.classList.toggle('rcm-error', error); el.hidden = false;
    clearTimeout(notifyCommunity.timer);
    notifyCommunity.timer = setTimeout(() => { el.hidden = true; }, error ? 10000 : 4500);
}
function renderSessionHeader() {
    const readers = document.getElementById('readerSession');
    if (!readers) return;
    readers.replaceChildren();
    readers.classList.toggle('hidden', !currentUser || Boolean(currentAdmin));
    if (currentUser && !currentAdmin) {
        readers.append(node('span', currentUser.username, 'rcm-username'));
        const out = node('button', 'Cerrar sesión'); out.type = 'button'; out.onclick = handleUserLogout;
        readers.append(out);
    }
    document.getElementById('guestAdminContainer').classList.toggle('hidden', Boolean(currentUser || currentAdmin));
    document.getElementById('rankingEditButton')?.classList.toggle('hidden', !currentAdmin);
    updateArticleEditorButton();
}
function updateArticleEditorButton(article) {
    article ||= articles.find(a => String(a.id) === String(activeModalArticleId));
    document.getElementById('editArticleButton')?.classList.toggle('hidden', !(currentAdmin && article?.remote));
}
function openArticleEditor() {
    const article = articles.find(a => String(a.id) === String(activeModalArticleId));
    if (!currentAdmin || !article?.remote) return;
    openPublishModal(); editingArticleId = article.id;
    for (const [id, value] of Object.entries({pubTitle: article.title, pubAuthor: article.author,
        pubCategory: article.category, pubImage: article.image, pubSummary: article.summary})) {
        document.getElementById(id).value = value || '';
    }
    const body = document.createElement('div'); body.innerHTML = cleanBody(article.body);
    editingBodyText = [...body.childNodes].map(n => n.textContent).join('\n').trim();
    editingBodyHTML = article.body;
    document.getElementById('pubBody').value = editingBodyText;
    document.getElementById('pubTitle').focus();
}

async function fetchAll(query) {
    const all = [];
    for (let offset = 0; ; offset += 200) {
        const {data, error} = await query().range(offset, offset + 199);
        if (error) throw error;
        all.push(...data); if (data.length < 200) return all;
    }
}
async function loadCommentsFromSupabase(articleId, quiet = false) {
    if (!db || articleId == null) return;
    const request = ++commentsRequest;
    const target = document.getElementById('modalCommentsList');
    if (!quiet && String(activeModalArticleId) === String(articleId)) target.textContent = 'Cargando comentarios…';
    try {
        const rows = await fetchAll(() => db.from('rcm_comment_totals').select('*')
            .eq('article_id', String(articleId)).order('created_at', {ascending: false}).order('id'));
        if (request !== commentsRequest || String(activeModalArticleId) !== String(articleId)) return;
        const article = articles.find(a => String(a.id) === String(articleId));
        if (!article) return;
        commentRows.clear(); rows.forEach(row => commentRows.set(String(row.id), row));
        // Keep the old article model compatible without writing these counts to storage.
        article.comments = rows.filter(c => !c.parent_id).map(c => ({id: c.id, text: c.body,
            author: c.author, upvotes: Number(c.upvotes), downvotes: Number(c.downvotes),
            myVote: Number(c.my_vote), date: c.created_at, replies: []}));
        // Avoid destroying a reader's unfinished reply during background refreshes.
        const signature = JSON.stringify(rows);
        if (!quiet || target.dataset.signature !== signature) {
            const pendingForms = [...target.querySelectorAll('form[data-reply]')].map(f => ({
                id: f.dataset.reply, value: f.querySelector('textarea').value, hidden: f.hidden
            }));
            renderCommentRows(rows, article);
            for (const saved of pendingForms) {
                const form = [...target.querySelectorAll('form[data-reply]')].find(f => f.dataset.reply === saved.id);
                if (form) { form.hidden = saved.hidden; form.querySelector('textarea').value = saved.value; }
            }
            target.dataset.signature = signature;
        }
        const anchor = new URL(location.href).searchParams.get('comment');
        if (anchor && !quiet) focusComment(anchor);
    } catch {
        if (request !== commentsRequest || String(activeModalArticleId) !== String(articleId)) return;
        if (!quiet) {
            target.replaceChildren(node('p', 'No pudimos cargar los comentarios y sus votos.'));
            const retry = node('button', 'Volver a intentar'); retry.onclick = () => loadCommentsFromSupabase(articleId);
            target.append(retry);
        } else notifyCommunity('No pudimos actualizar los comentarios. Los datos mostrados pueden estar desactualizados.', true);
    }
}
function renderModalComments(article) {
    if (String(article.id) === String(activeModalArticleId)) loadCommentsFromSupabase(article.id);
}
function renderCommentRows(rows, article) {
    const target = document.getElementById('modalCommentsList'); target.replaceChildren();
    updateCommentAuthUI();
    const count = document.getElementById('modalCommentCount'); if (count) count.textContent = rows.length;
    if (!rows.length) { target.append(node('p', 'Aún no hay comentarios. Abre la conversación.')); return; }
    const columns = node('div', null, 'rcm-comment-columns');
    const positive = node('section'), negative = node('section');
    positive.append(node('h3', '▲ Más apoyados')); negative.append(node('h3', '▼ Más cuestionados'));
    columns.append(positive, negative); target.append(columns);
    const roots = rows.filter(c => !c.parent_id || !rows.some(parent => String(parent.id) === String(c.parent_id)));
    roots.sort((a,b) => Number(b.upvotes) - Number(a.upvotes) || new Date(b.created_at) - new Date(a.created_at));
    const rendered = new Set();
    function card(row, depth = 0) {
        if (rendered.has(String(row.id))) return node('span');
        rendered.add(String(row.id));
        const el = node('article', null, 'rcm-comment'); el.id = 'comment-' + row.id; el.tabIndex = -1;
        const header = node('div', null, 'rcm-row');
        header.append(node('strong', row.author || 'Usuario'), node('time', new Date(row.created_at).toLocaleDateString('es')));
        const body = node('p', row.body, 'rcm-comment-body');
        const controls = node('div', null, 'rcm-row');
        for (const direction of [1,-1]) {
            const label = direction === 1 ? '▲ ' + row.upvotes : '▼ ' + row.downvotes;
            const vote = node('button', label); vote.type = 'button';
            vote.setAttribute('aria-label', (direction === 1 ? 'Votar a favor: ' : 'Votar en contra: ') + (direction === 1 ? row.upvotes : row.downvotes));
            vote.setAttribute('aria-pressed', String(Number(row.my_vote) === direction));
            vote.dataset.voteComment = String(row.id); vote.disabled = votePending.has(String(row.id));
            vote.onclick = () => voteComment(article.id, row.id, direction);
            controls.append(vote);
        }
        const reply = node('button', 'Responder'); reply.type = 'button'; reply.setAttribute('aria-expanded', 'false'); controls.append(reply);
        const form = node('form'); form.hidden = true; form.dataset.reply = String(row.id);
        const input = node('textarea'); input.required = true; input.maxLength = 2000; input.rows = 3;
        input.placeholder = 'Escribe tu respuesta…'; input.setAttribute('aria-label', 'Respuesta a ' + (row.author || 'Usuario'));
        const submit = node('button', 'Publicar respuesta'); submit.type = 'submit'; form.append(input, submit);
        reply.onclick = () => {
            if (!currentUser) { openUserAuthModal(); return; }
            form.hidden = !form.hidden; reply.setAttribute('aria-expanded', String(!form.hidden));
            if (!form.hidden) input.focus();
        };
        form.onsubmit = async event => {
            event.preventDefault(); if (!currentUser) { openUserAuthModal(); return; }
            const text = input.value.trim(); if (!text || submit.disabled) return;
            submit.disabled = true;
            try {
                const {error} = await db.from('comments').insert({article_id: String(article.id), parent_id: row.id,
                    user_id: currentUser.id, author: currentUser.username, body: text});
                if (error) throw error;
                input.value = ''; form.hidden = true;
                await loadCommentsFromSupabase(article.id, true); await refreshCommunity();
                notifyCommunity('Respuesta publicada.');
            } catch { notifyCommunity('No se pudo publicar tu respuesta. Conservamos el texto para reintentar.', true); }
            finally { submit.disabled = false; }
        };
        el.append(header, body, controls, form);
        const children = rows.filter(c => String(c.parent_id) === String(row.id));
        for (const child of children) {
            const childCard = card(child, depth + 1);
            // Indent only one level, so long threads remain readable on mobile.
            if (depth === 0) childCard.classList.add('rcm-reply');
            el.append(childCard);
        }
        return el;
    }
    const positives = roots.filter(c => Number(c.downvotes) <= Number(c.upvotes));
    const negatives = roots.filter(c => Number(c.downvotes) > Number(c.upvotes))
        .sort((a,b) => Number(b.downvotes) - Number(a.downvotes) || new Date(b.created_at) - new Date(a.created_at));
    positives.forEach(c => positive.append(card(c))); negatives.forEach(c => negative.append(card(c)));
    if (!positives.length) positive.append(node('p', 'No hay comentarios en este grupo.'));
    if (!negatives.length) negative.append(node('p', 'No hay comentarios en este grupo.'));
}
async function voteComment(articleId, commentId, direction) {
    if (!currentUser) { openUserAuthModal(); return; }
    const key = String(commentId), row = commentRows.get(key);
    if (!row || votePending.has(key) || ![1,-1].includes(direction)) return;
    votePending.add(key);
    const buttons = [...document.querySelectorAll('[data-vote-comment]')].filter(b => b.dataset.voteComment === key);
    buttons.forEach(b => { b.disabled = true; });
    try {
        // Set an explicit target state, so retries cannot inadvertently toggle twice.
        const desired = Number(row.my_vote) === direction ? 0 : direction;
        const {error} = await db.rpc('rcm_set_comment_vote', {p_comment_id: key, p_vote: desired});
        if (error) throw error;
        await Promise.all([loadCommentsFromSupabase(articleId, true), refreshCommunity()]);
    } catch {
        notifyCommunity('No pudimos confirmar el voto. No cambiamos el contador; vuelve a cargar para comprobarlo.', true);
    } finally {
        votePending.delete(key);
        document.querySelectorAll('[data-vote-comment]').forEach(b => { if (b.dataset.voteComment === key) b.disabled = false; });
    }
}
async function refreshCommunity() {
    if (!db) return;
    const request = ++communityRequest;
    const target = document.getElementById('communityLeaders');
    try {
        const {data, error} = await db.rpc('rcm_community_leaders'); if (error) throw error;
        if (request !== communityRequest) return;
        target.replaceChildren();
        for (const [key, title] of [['supported','Más apoyado'], ['questioned','Más cuestionado']]) {
            const panel = node('div', null, 'rcm-leader'); panel.append(node('h3', title));
            const row = data?.[key];
            if (!row) { panel.append(node('p', 'Todavía no hay comentarios con votos de este tipo.')); }
            else {
                const link = node('a', null, 'rcm-leader-link');
                const url = articleURL(row.article_id, row.id); link.href = url;
                link.append(node('blockquote', row.body.length > 190 ? row.body.slice(0,190) + '…' : row.body),
                    node('p', row.author || 'Usuario'), node('p', `▲ ${row.upvotes} · ▼ ${row.downvotes}`), node('strong', row.article_title));
                link.onclick = async event => {
                    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
                    event.preventDefault(); history.pushState({}, '', url);
                    await openArticleFromShareLink();
                };
                panel.append(link);
            }
            target.append(panel);
        }
    } catch {
        if (request === communityRequest) target.replaceChildren(node('p', 'No pudimos cargar los comentarios destacados. Volveremos a intentarlo.'));
    }
}
function articleURL(articleId, commentId = null) {
    const url = new URL(location.href); url.searchParams.set('article', String(articleId));
    url.hash = ''; url.searchParams.delete('comment');
    if (commentId != null) url.searchParams.set('comment', String(commentId));
    return url.toString();
}
async function openArticleFromShareLink() {
    const articleId = new URL(location.href).searchParams.get('article');
    document.getElementById('articleMissing').classList.add('hidden');
    if (!articleId) {
        activeModalArticleId = null; ++commentsRequest;
        document.getElementById('articleModal').classList.add('hidden'); syncModalScrollLock(); return;
    }
    let article = articles.find(a => String(a.id) === String(articleId) || a.legacyId === articleId);
    if (!article && db) {
        const field = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(articleId) ? 'id' : 'legacy_id';
        const {data, error} = await db.from('articles').select('*').eq(field, articleId).eq('is_public', true).maybeSingle();
        if (new URL(location.href).searchParams.get('article') !== articleId) return;
        if (error) {
            notifyCommunity('No pudimos consultar esta publicación. Comprueba la conexión y vuelve a intentarlo.', true);
            return;
        }
        if (data) { article = fromDatabase(data); articles.push(article); }
    }
    if (!article) {
        document.getElementById('articleModal').classList.add('hidden'); activeModalArticleId = null;
        document.getElementById('articleMissing').classList.remove('hidden');
        document.getElementById('articleMissing').scrollIntoView(); syncModalScrollLock(); return;
    }
    openArticleModal(article.id, {updateUrl: false});
}
function focusComment(id) {
    const el = document.getElementById('comment-' + id);
    if (el) { el.scrollIntoView({block: 'center', behavior: 'auto'}); el.focus({preventScroll: true}); }
    else notifyCommunity('Este comentario ya no está disponible.');
}
window.addEventListener('popstate', openArticleFromShareLink);
async function copyShareLink() {
    if (activeModalArticleId == null) return;
    const link = articleURL(activeModalArticleId);
    try {
        await navigator.clipboard.writeText(link); notifyCommunity('Enlace copiado.');
    } catch {
        // Accessible fallback: selected, visible text rather than a silent failed copy.
        const dialog = document.createElement('dialog'); dialog.className = 'rcm-dialog';
        const input = node('input'); input.value = link; input.readOnly = true; input.setAttribute('aria-label', 'Enlace de la publicación');
        const close = node('button', 'Cerrar'); close.onclick = () => dialog.close();
        dialog.append(node('p', 'Copia este enlace:'), input, close); document.body.append(dialog);
        dialog.addEventListener('close', () => dialog.remove()); dialog.showModal(); input.select();
    }
}
async function shareArticle() {
    const article = articles.find(a => String(a.id) === String(activeModalArticleId)); if (!article) return;
    if (!navigator.share) return copyShareLink();
    try { await navigator.share({title: article.title, text: article.summary, url: articleURL(article.id)}); }
    catch (error) { if (error.name !== 'AbortError') await copyShareLink(); }
}

function teamNode(id, position) {
    const team = NFL_TEAMS.find(t => t.id === id);
    const item = node('li', null, 'rcm-team');
    item.append(node('strong', String(position)));
    if (team) {
        const image = node('img'); image.src = team.logo; image.alt = ''; image.width = 36; image.height = 36;
        image.loading = 'lazy'; image.onerror = () => { image.replaceWith(node('span', team.id, 'rcm-logo-fallback')); };
        item.append(image, node('span', team.name));
    } else item.append(node('span', id || 'Equipo no disponible'));
    return item;
}
async function loadRanking(quiet = false) {
    if (!db) return;
    try {
        const {data, error} = await db.from('nfl_rankings').select('*').eq('id',1).maybeSingle();
        if (error) throw error;
        if (quiet && JSON.stringify(data) === JSON.stringify(rankingPublished)) return;
        rankingPublished = data; renderRanking();
    } catch { document.getElementById('rankingStatus').textContent = 'No pudimos cargar el ranking. Comprueba la conexión; volveremos a intentarlo.'; }
}
function renderRanking() {
    const list = document.getElementById('rankingList'), track = document.getElementById('rankingTrack');
    list.replaceChildren(); track.replaceChildren();
    document.getElementById('rankingPause').classList.toggle('hidden', !rankingPublished);
    document.getElementById('rankingStatic').classList.toggle('hidden', !rankingPublished);
    document.getElementById('rankingEdition').textContent = rankingPublished ? `${rankingPublished.edition} · Actualizado: ${new Date(rankingPublished.updated_at).toLocaleString('es')}` : '';
    document.getElementById('rankingStatus').textContent = rankingPublished ? '' : 'Aún no hay un ranking publicado. Nuestro equipo está preparando la primera edición.';
    if (!rankingPublished) return;
    rankingPublished.team_ids.forEach((id,i) => list.append(teamNode(id,i+1)));
    for (let copy=0; copy<2; copy++) {
        const group = node('ol', null, 'rcm-track-group');
        rankingPublished.team_ids.forEach((id,i) => group.append(teamNode(id,i+1))); track.append(group);
    }
    applyRankingMotion();
}
function applyRankingMotion() {
    document.getElementById('rankingTrack').classList.toggle('paused', rankingPaused);
    const button = document.getElementById('rankingPause');
    button.textContent = rankingPaused ? 'Reanudar movimiento' : 'Pausar movimiento';
    button.setAttribute('aria-pressed', String(rankingPaused));
}
function toggleRankingMotion() { rankingPaused = !rankingPaused; applyRankingMotion(); }
async function openRankingEditor() {
    if (!currentAdmin || rankingBusy || !db) return;
    let dialog = document.getElementById('rankingDialog'); if (dialog) return;
    dialog = node('dialog', null, 'rcm-dialog'); dialog.id = 'rankingDialog';
    dialog.setAttribute('aria-labelledby','rankingEditorTitle');
    const title = node('h2', 'Editar NFL Power Rankings'); title.id = 'rankingEditorTitle';
    const status = node('p', 'Cargando borrador…'); status.id = 'rankingEditorStatus'; status.setAttribute('role','status');
    const close = node('button','Cerrar'); close.type='button'; close.onclick=()=>dialog.close();
    dialog.append(title, status, close); dialog.addEventListener('close',()=>dialog.remove());
    document.body.append(dialog); dialog.showModal();
    try {
        const [draftResult,publishedResult] = await Promise.all([
            db.from('nfl_ranking_drafts').select('*').eq('user_id',currentAdmin.id).maybeSingle(),
            db.from('nfl_rankings').select('*').eq('id',1).maybeSingle()
        ]);
        if (draftResult.error || publishedResult.error) throw new Error('No pudimos cargar el editor. Cierra y vuelve a intentarlo.');
        const source = draftResult.data || publishedResult.data;
        rankingDraft = source?.team_ids ? [...source.team_ids] : Array(10).fill('');
        rankingEditingBase = publishedResult.data?.updated_at || null;
        const label=node('label','Semana o edición'); label.htmlFor='rankingEditionInput';
        const edition=node('input'); edition.id='rankingEditionInput'; edition.maxLength=100; edition.value=source?.edition||''; edition.placeholder='Ej.: Semana 7 · 2026';
        const rows=node('div'); rows.id='rankingEditorRows';
        const save=node('button','Guardar borrador'); save.type='button'; save.onclick=()=>saveRanking(false);
        const publish=node('button','Publicar las diez posiciones'); publish.type='button'; publish.onclick=()=>saveRanking(true);
        dialog.append(label,edition,rows,save,publish);
        status.textContent='El borrador es privado para tu cuenta. El público solo verá los cambios cuando pulses Publicar.';
        renderRankingEditorRows();
    } catch(error) { status.textContent=error.message; }
}
function renderRankingEditorRows() {
    const parent=document.getElementById('rankingEditorRows'); if (!parent) return; parent.replaceChildren();
    rankingDraft.forEach((id,i)=>{
        const row=node('div',null,'rcm-ranking-edit-row');
        const label=node('label',String(i+1)); label.htmlFor='rank-'+i;
        const select=node('select'); select.id='rank-'+i; select.setAttribute('aria-label','Equipo en posición '+(i+1));
        select.append(new Option('Seleccionar equipo',''));
        NFL_TEAMS.forEach(team=>{const option=new Option(team.name,team.id); option.disabled=rankingDraft.includes(team.id)&&team.id!==id; select.append(option);});
        select.value=id; select.onchange=()=>{rankingDraft[i]=select.value;renderRankingEditorRows();document.getElementById('rank-'+i).focus();};
        row.append(label,select);
        for (const [delta,text] of [[-1,'↑'],[1,'↓']]) {
            const button=node('button',text); button.type='button'; button.disabled=i+delta<0||i+delta>=10;
            button.setAttribute('aria-label',(delta===-1?'Subir':'Bajar')+' equipo en posición '+(i+1));
            button.onclick=()=>{[rankingDraft[i],rankingDraft[i+delta]]=[rankingDraft[i+delta],rankingDraft[i]];renderRankingEditorRows();document.getElementById('rank-'+(i+delta)).focus();}; row.append(button);
        }
        parent.append(row);
    });
}
async function saveRanking(publish) {
    if (!currentAdmin||rankingBusy) return;
    const status=document.getElementById('rankingEditorStatus');
    const edition=document.getElementById('rankingEditionInput').value.trim();
    if (!edition) {status.textContent='Escribe una semana o edición.';return;}
    if (publish&&(rankingDraft.length!==10||rankingDraft.some(id=>!NFL_TEAMS.some(t=>t.id===id))||new Set(rankingDraft).size!==10)) {
        status.textContent='Selecciona diez equipos distintos antes de publicar.';return;
    }
    rankingBusy=true; document.querySelectorAll('#rankingDialog button, #rankingDialog select, #rankingDialog input').forEach(e=>e.disabled=true);
    status.textContent=publish?'Publicando…':'Guardando borrador…';
    try {
        const result=publish?await db.rpc('rcm_publish_ranking',{p_edition:edition,p_team_ids:[...rankingDraft],p_expected_updated_at:rankingEditingBase})
            :await db.from('nfl_ranking_drafts').upsert({user_id:currentAdmin.id,edition,team_ids:[...rankingDraft]},{onConflict:'user_id'});
        if(result.error) throw result.error;
        if(publish){ await loadRanking();rankingEditingBase=rankingPublished?.updated_at||null; }
        status.textContent=publish?'Ranking publicado. Las diez posiciones se guardaron juntas.':'Borrador guardado. El ranking público no ha cambiado.';
    } catch(error) {
        status.textContent=error.message?.includes('RCM_CONFLICT')?'Otro administrador publicó cambios. Cierra y vuelve a abrir el editor para revisar la versión actual.':'No se pudo confirmar el guardado. Conservamos tus cambios; revisa la conexión y vuelve a intentarlo.';
    } finally {
        rankingBusy=false;document.querySelectorAll('#rankingDialog button, #rankingDialog input').forEach(e=>e.disabled=false);renderRankingEditorRows();
    }
}
async function refreshVisibleCommunity() {
    if (document.hidden||refreshInFlight||!db) return;
    refreshInFlight=true;
    try { await Promise.all([refreshCommunity(),currentCategory==='NFL'?loadRanking(true):Promise.resolve(),
        activeModalArticleId!=null?loadCommentsFromSupabase(activeModalArticleId,true):Promise.resolve()]); }
    finally {refreshInFlight=false;}
}
window.addEventListener('DOMContentLoaded',()=>{
    refreshCommunity();loadRanking();
    // A bounded background refresh shares other visitors' changes, with no Realtime setup required.
    setInterval(refreshVisibleCommunity,30000);
    document.addEventListener('visibilitychange',refreshVisibleCommunity);
    if(db)db.auth.onAuthStateChange(()=>setTimeout(async()=>{
        await Promise.all([loadUserSession(),loadAdminSession()]);
        if(activeModalArticleId!=null)await loadCommentsFromSupabase(activeModalArticleId,true);
        renderSessionHeader();
        if(!currentAdmin)document.getElementById('rankingDialog')?.close();
    },0));
});

// Keep keyboard focus inside the login dialog, including when an article is open.
document.addEventListener('keydown', event => {
    const modal = document.getElementById('userAuthModal');
    if (modal.classList.contains('hidden')) return;
    if (event.key === 'Escape') { closeUserAuthModal(); event.preventDefault(); return; }
    if (event.key !== 'Tab') return;
    const controls = [...modal.querySelectorAll('button:not(:disabled),input:not(:disabled)')];
    const first = controls[0], last = controls.at(-1);
    if (event.shiftKey && document.activeElement === first) { last.focus(); event.preventDefault(); }
    else if (!event.shiftKey && document.activeElement === last) { first.focus(); event.preventDefault(); }
});
