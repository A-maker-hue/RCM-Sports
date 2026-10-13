/* Browser integration tests with an explicit fake Supabase transport. Never uses production credentials. */
const {createRequire}=require('node:module');
const requireRuntime=createRequire(__filename);
const {chromium}=requireRuntime(process.env.RCM_PLAYWRIGHT||'playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const root='http://127.0.0.1:8765/RCM-Sports/';
const aid='10000000-0000-0000-0000-000000000001';
const state={votes:{},failVotes:false,ranking:null,drafts:{},articles:[{id:aid,legacy_id:'1',title:'Análisis NFL de prueba',category:'NFL',author:'Redacción',image:'https://example.test/image.jpg',summary:'Resumen de prueba',body:'<p>Contenido del artículo.</p>',created_at:'2026-10-12T12:00:00Z',featured:true,is_public:true}],comments:[{id:'c1',article_id:aid,parent_id:null,author:'Lector <img src=x onerror=alert(1)>',body:'Comentario de prueba <script>window.pwned=1</script>',created_at:'2026-10-12T12:00:00Z'}]};
const mockClient=`(()=>{
let user=JSON.parse(localStorage.getItem('testSession')||'null');const listeners=[];
window.supabase={createClient:()=>({
 auth:{getUser:async()=>({data:{user},error:null}),onAuthStateChange:fn=>{listeners.push(fn);return {data:{subscription:{unsubscribe(){}}}}},
 signInWithPassword:async({email})=>{const name=email.split('@')[0];user={id:name,email,user_metadata:{username:name}};localStorage.setItem('testSession',JSON.stringify(user));listeners.forEach(f=>f());return {data:{user,session:{}},error:null}},
 signUp:async({email,options})=>{user={id:options.data.username,email,user_metadata:options.data};localStorage.setItem('testSession',JSON.stringify(user));listeners.forEach(f=>f());return {data:{user,session:{}},error:null}},
 signOut:async()=>{user=null;localStorage.removeItem('testSession');listeners.forEach(f=>f());return {error:null}}},
 from:table=>{let q={table,user:user?.id,filters:[],op:'select'};const b={select:()=>b,eq:(k,v)=>{q.filters.push([k,v]);return b},order:()=>b,range:(a,z)=>{q.range=[a,z];return b},maybeSingle:()=>{q.single=true;return b},single:()=>{q.single=true;return b},insert:v=>{q.op='insert';q.payload=v;return b},update:v=>{q.op='update';q.payload=v;return b},upsert:v=>{q.op='upsert';q.payload=v;return b},delete:()=>{q.op='delete';return b},then:(a,z)=>window.mockDb(q).then(a,z)};return b},
 rpc:(name,args)=>window.mockDb({rpc:name,args,user:user?.id})
})};})();`;
function totals(user){return state.comments.filter(c=>state.articles.some(a=>a.id===c.article_id&&a.is_public)).map(c=>{
 const votes=Object.entries(state.votes).filter(([key])=>key.startsWith(c.id+':'));
 return {...c,article_title:state.articles.find(a=>a.id===c.article_id).title,upvotes:votes.filter(([,v])=>v===1).length,downvotes:votes.filter(([,v])=>v===-1).length,my_vote:state.votes[c.id+':'+user]||0};
});}
async function backend(q){
 if(q.rpc){
  if(q.rpc==='rcm_set_comment_vote'){if(state.failVotes)return {error:{message:'offline'}};state.votes[q.args.p_comment_id+':'+q.user]=q.args.p_vote;return {data:null,error:null};}
  if(q.rpc==='rcm_community_leaders'){const rows=totals(q.user);const top=key=>rows.filter(c=>c[key]>0).sort((a,b)=>b[key]-a[key]||b.created_at.localeCompare(a.created_at))[0]||null;return {data:{supported:top('upvotes'),questioned:top('downvotes')}};}
  if(q.rpc==='rcm_publish_ranking'){state.ranking={id:1,edition:q.args.p_edition,team_ids:q.args.p_team_ids,updated_at:new Date().toISOString()};return {data:null};}
 }
 let rows=q.table==='articles'?state.articles.filter(a=>a.is_public):q.table==='editors'?(q.user==='admin'?[{user_id:'admin'}]:[]):q.table==='rcm_comment_totals'?totals(q.user):q.table==='nfl_rankings'?(state.ranking?[state.ranking]:[]):q.table==='nfl_ranking_drafts'?(state.drafts[q.user]?[state.drafts[q.user]]:[]):q.table==='comments'?state.comments:[];
 const matches=x=>q.filters.every(([k,v])=>String(x[k])===String(v));
 if(q.op==='insert'&&q.table==='comments'){const row={...q.payload,id:'c'+(state.comments.length+1),created_at:new Date().toISOString()};state.comments.push(row);return {data:q.single?row:[row]};}
 if(q.op==='update'&&q.table==='articles'){const row=state.articles.find(matches);Object.assign(row,q.payload);return {data:row};}
 if(q.op==='upsert'&&q.table==='nfl_ranking_drafts'){state.drafts[q.user]=q.payload;return {data:q.payload};}
 rows=rows.filter(matches);if(q.range)rows=rows.slice(q.range[0],q.range[1]+1);
 return {data:JSON.parse(JSON.stringify(q.single?(rows[0]||null):rows)),error:null};
}
(async()=>{
 let opts={headless:true};
 if(process.env.RCM_CHROME_PATH)opts={...opts,executablePath:process.env.RCM_CHROME_PATH,args:['--no-sandbox','--disable-dev-shm-usage','--disable-gpu']};
 if(process.env.RCM_CHROMIUM){const imported=await import(process.env.RCM_CHROMIUM);const bin=imported.default||imported;opts={...opts,executablePath:await bin.executablePath(),args:bin.args};}
 const path=require('node:path');
 const server=require('node:http').createServer((req,res)=>{
  const pathname=new URL(req.url,'http://localhost').pathname;
  const relative=pathname.replace(/^\/RCM-Sports\//,'')||'index.html';
  const file=path.resolve(__dirname,'..',relative);
  if(!file.startsWith(path.resolve(__dirname,'..')+path.sep)){res.writeHead(403);res.end();return;}
  try{const bytes=fs.readFileSync(file);res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html');res.end(bytes);}catch{res.writeHead(404);res.end();}
 });
 await new Promise(resolve=>server.listen(8765,'127.0.0.1',resolve));
 const browser=await chromium.launch(opts);
 const errors=[];
 async function newPage(viewport={width:1280,height:900}){
  const context=await browser.newContext({viewport});const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
  await page.exposeFunction('mockDb',backend);
  await page.route('**/supabase-js@2',r=>r.fulfill({contentType:'text/javascript',body:mockClient}));
  await page.route('**/*',async r=>{
   const url=r.request().url();
   if(url.includes('/supabase-js@2'))return r.fallback();
   if(url.startsWith('http://127.0.0.1'))return r.continue();
   // Keep actual CDN Tailwind for screenshot when available; all private/live services remain blocked.
   if(url==='https://cdn.tailwindcss.com'&&fs.existsSync('/tmp/rcm-tailwind.js'))return r.fulfill({contentType:'text/javascript',body:fs.readFileSync('/tmp/rcm-tailwind.js')});
   if(url.includes('tailwindcss.com'))return r.fulfill({contentType:'text/javascript',body:'window.tailwind={};'});
   return r.abort();
  });
  return page;
 }
 async function ready(page,url=root){await page.goto(url);await page.waitForFunction(()=>typeof articles!=='undefined'&&articles.some(a=>a.remote));}
 async function login(page,name){await page.evaluate(()=>openUserAuthModal());await page.locator('#userAuthUsername').fill(name);await page.locator('#userAuthPassword').fill('password123');await page.locator('#userAuthModal button[type=submit]').click();await page.waitForFunction(name=>currentUser?.id===name,name);await page.waitForTimeout(150);}
 const one=await newPage(),two=await newPage();await ready(one,root+'?article='+aid);await ready(two,root+'?article='+aid);
 await one.locator('#comment-c1').waitFor();assert.equal(await one.evaluate(()=>window.pwned),undefined);assert.equal(await one.locator('#comment-c1 script').count(),0);
 await login(one,'alice');await login(two,'bob');
 await one.locator('#comment-c1 button').nth(0).click();await one.waitForFunction(()=>commentRows.get('c1').upvotes===1);
 await two.locator('#comment-c1 button').nth(0).click();await two.waitForFunction(()=>commentRows.get('c1').upvotes===2);
 await one.evaluate(()=>refreshVisibleCommunity());assert.equal(await one.locator('#comment-c1 button').nth(0).textContent(),'▲ 2');
 await one.locator('#comment-c1 button').nth(1).click();await one.waitForFunction(()=>commentRows.get('c1').my_vote===-1);assert.equal(await one.locator('#comment-c1 button').nth(0).textContent(),'▲ 1');
 await one.locator('#comment-c1 button').nth(1).click();await one.waitForFunction(()=>commentRows.get('c1').my_vote===0);
 state.failVotes=true;await one.locator('#comment-c1 button').nth(0).click();await one.waitForFunction(()=>document.getElementById('communityNotice')?.textContent.includes('No pudimos confirmar'));assert.equal(await one.locator('#comment-c1 button').nth(0).textContent(),'▲ 1');state.failVotes=false;
 await one.evaluate(()=>{Object.defineProperty(navigator,'clipboard',{configurable:true,value:{writeText:async text=>{window.testCopied=text;}}});});
 await one.getByRole('button',{name:'Copiar enlace',exact:true}).click();assert.ok((await one.evaluate(()=>window.testCopied)).endsWith('?article='+aid));
 await one.evaluate(()=>{Object.defineProperty(navigator,'share',{configurable:true,value:async data=>{window.testShared=data;}});});
 await one.getByRole('button',{name:'Compartir publicación',exact:true}).click();assert.equal((await one.evaluate(()=>window.testShared)).title,'Análisis NFL de prueba');
 await one.evaluate(()=>{Object.defineProperty(navigator,'clipboard',{configurable:true,value:{writeText:async()=>{throw Error('denied')}}});});
 await one.getByRole('button',{name:'Copiar enlace',exact:true}).click();await one.locator('dialog input').waitFor();assert.ok((await one.locator('dialog input').inputValue()).includes('article='+aid));await one.locator('dialog button').click();
 await two.reload();await two.locator('#comment-c1').waitFor();await two.waitForFunction(()=>commentRows.get('c1')?.my_vote===1);
 await two.evaluate(()=>handleUserLogout());await two.waitForFunction(()=>commentRows.get('c1')?.my_vote===0);assert.equal(await two.locator('#comment-c1 button').nth(0).textContent(),'▲ 1');
 await two.locator('#comment-c1 button').nth(0).click();await two.locator('#userAuthModal:not(.hidden)').waitFor();assert.equal(await two.locator('#articleModal').evaluate(el=>el.classList.contains('hidden')),false);await two.evaluate(()=>closeUserAuthModal());
 // Browser history and stable alias.
 await one.evaluate(()=>closeModal());assert.ok(!one.url().includes('article='));await one.goBack();await one.locator('#comment-c1').waitFor();await one.goForward();assert.equal(await one.locator('#articleModal').evaluate(el=>el.classList.contains('hidden')),true);
 await ready(one,root+'?article=1');await one.locator('#comment-c1').waitFor();
 await ready(one,root+'?article=00000000-0000-0000-0000-000000000099');await one.locator('#articleMissing:not(.hidden)').waitFor();await one.locator('#articleMissing button').click();
 await one.evaluate(()=>filterByCategory('NFL'));assert.equal(await one.locator('#nflRankings').evaluate(el=>el.classList.contains('hidden')),false);assert.match(await one.locator('#rankingStatus').textContent(),/Aún no hay/);
 await one.evaluate(()=>{document.getElementById('searchInput').value='no-match';handleSearch();});assert.equal(await one.locator('#noResults').evaluate(el=>el.classList.contains('hidden')),false);await one.evaluate(()=>resetFilters());
 await login(one,'admin');await one.waitForFunction(()=>currentAdmin?.id==='admin');await one.evaluate(()=>openArticleModal(articles[0].id));await one.locator('#editArticleButton').click();await one.locator('#pubImage').fill('https://example.test/new-image.jpg');await one.locator('#publishModal form button[type=submit]').click();await one.waitForFunction(()=>articles[0].image.includes('new-image'));assert.equal(state.articles[0].body,'<p>Contenido del artículo.</p>');assert.equal(state.articles[0].id,aid);
 await one.evaluate(()=>closeModal());await one.evaluate(()=>filterByCategory('NFL'));await one.locator('#rankingEditButton').click();await one.locator('#rankingEditionInput').fill('Semana de prueba');
 await one.getByRole('button',{name:'Publicar las diez posiciones'}).click();assert.match(await one.locator('#rankingEditorStatus').textContent(),/diez equipos distintos/);
 const teams=['ARI','ATL','BAL','BUF','CAR','CHI','CIN','CLE','DAL','DEN'];for(let i=0;i<10;i++)await one.locator('#rank-'+i).selectOption(teams[i]);
 await one.getByRole('button',{name:'Guardar borrador',exact:true}).click();await one.waitForFunction(()=>document.getElementById('rankingEditorStatus').textContent.includes('Borrador guardado'));assert.equal(state.ranking,null);
 await one.getByRole('button',{name:'Publicar las diez posiciones'}).click();await one.waitForFunction(()=>document.getElementById('rankingEditorStatus').textContent.includes('Ranking publicado'));
 await one.getByRole('button',{name:'Cerrar',exact:true}).click();await two.evaluate(()=>{filterByCategory('NFL');loadRanking();});await two.waitForFunction(()=>rankingPublished?.team_ids.length===10);assert.equal(await two.locator('#rankingList li').count(),10);
 await one.locator('#rankingPause').click();assert.equal(await one.locator('#rankingTrack').evaluate(e=>e.classList.contains('paused')),true);
 await one.screenshot({path:'/tmp/rcm-desktop.png',fullPage:true});
 const mobile=await newPage({width:390,height:844});await ready(mobile);await mobile.evaluate(()=>filterByCategory('NFL'));await mobile.waitForFunction(()=>rankingPublished?.team_ids.length===10);await mobile.screenshot({path:'/tmp/rcm-mobile.png',fullPage:true});
 assert.equal(await mobile.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth),true);
 await mobile.emulateMedia({reducedMotion:'reduce'});assert.equal(await mobile.locator('#rankingTrack').evaluate(e=>getComputedStyle(e).animationName),'none');
 await one.evaluate(()=>closeModal());await one.locator('#communityLeaders a').first().click();await one.waitForFunction(()=>document.activeElement?.id==='comment-c1');
 assert.deepEqual(errors,[]);console.log('PASS: mock-transport browser integration: two readers, votes/change/remove/error/reload/logout, escaped content, deep links/alias/history/not-found, login over article, NFL filter/search, image edit preserves ID/body, draft/publish ranking, shared ranking, reduced motion, mobile width, highlighted comment navigation.');
 await browser.close();server.close();
})().catch(e=>{console.error(e.stack);process.exit(1)});
