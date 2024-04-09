<script lang="ts">
  import { onMount, onDestroy } from 'svelte';  
  import { initApp, cleanupApp } from './appInit';
  import AudioPlayer from './lib/AudioPlayer.svelte';
  import Topbar from "./lib/Topbar.svelte";
  import Sidebar from "./lib/Sidebar.svelte";
  import Settings from "./lib/Settings.svelte";
  import SvelteMarkdown from "svelte-markdown";
  import CodeRenderer from "./renderers/Code.svelte";
  import EmRenderer from "./renderers/Em.svelte";
  import ListRenderer from "./renderers/ListRenderer.svelte";
  import ListItemRenderer from "./renderers/ListItem.svelte";
  import CodeSpanRenderer from "./renderers/CodeSpan.svelte";
  import ParagraphRenderer from "./renderers/Paragraph.svelte";
  import HtmlRenderer from "./renderers/Html.svelte";
  import DeleteIcon from "./assets/delete.svg";
  import CopyIcon from "./assets/CopyIcon.svg"; 
  import MoreIcon from "./assets/more.svg";
  import SendIcon from "./assets/send.svg";
  import WaitIcon from "./assets/wait.svg"; 
  import  UploadIcon from "./assets/upload-icon.svg";
  import { afterUpdate } from "svelte";
  import { conversations, chosenConversationId, settingsVisible, clearFileInputSignal } from "./stores/stores";
  import { isAudioMessage, formatMessageForMarkdown } from "./utils/generalUtils";
  import { routeMessage, newChat, deleteMessageFromConversation } from "./managers/conversationManager";
  import { copyTextToClipboard } from './utils/generalUtils';
  import { selectedModel, selectedVoice, selectedMode, isStreaming } from './stores/stores';
  import { reloadConfig } from './services/openaiService';
  import { handleImageUpload, onSendVisionMessageComplete } from './managers/imageManager';
  import { base64Images } from './stores/stores';
  import { closeStream } from './services/openaiService';  

  let fileInputElement; // This will hold the reference to your file input element
  let input: string = "";
  let chatContainer: HTMLElement;
  let moreButtonsToggle: boolean = false;
  let conversationTitle = "";

  $: if ($clearFileInputSignal && fileInputElement) {
    fileInputElement.value = '';
    clearFileInputSignal.set(false); // Reset the signal
  }

  $: {
    const currentConversationId = $chosenConversationId;
    const currentConversations = $conversations;
    const totalConversations = $conversations.length;

    if (currentConversationId !== undefined && currentConversations[currentConversationId]) {
      conversationTitle = currentConversations[currentConversationId].title || "New Conversation";
    }
    if (currentConversationId === undefined || currentConversationId === null || currentConversationId < 0 || currentConversationId >= totalConversations) {
      console.log("changing conversation from ID", $chosenConversationId);
      chosenConversationId.set(totalConversations > 0 ? totalConversations - 1 : null);
      console.log("to ID", $chosenConversationId);

    }
  }
  
  let chatContainerObserver: MutationObserver | null = null;  
  
  function setupMutationObserver() {    
    if (!chatContainer) return; // Ensure chatContainer is mounted  
  
    const config = { childList: true, subtree: true, characterData: true };  
  
    chatContainerObserver = new MutationObserver((mutationsList, observer) => {  
      // Trigger scroll if any relevant mutations observed  
      scrollChatToEnd();  
    });  
  
    chatContainerObserver.observe(chatContainer, config);    
  }  

  onMount(async () => {  
    await initApp();  
  
    // Setup MutationObserver after app initialization and component mounting  
    setupMutationObserver();  
  });  
  
  onDestroy(() => {  
    // Clean up MutationObserver when component is destroyed to prevent memory leaks  
    if (chatContainerObserver) {  
      chatContainerObserver.disconnect();  
      chatContainerObserver = null;  
    }  
    // Clean up app-specific resources  
    cleanupApp();  
  });  

  function scrollChatToEnd() {    
  if (chatContainer) {    
    const threshold = 150; // How close to the bottom (in pixels) to trigger auto-scroll  
    const isNearBottom = chatContainer.scrollHeight - chatContainer.scrollTop - threshold <= chatContainer.clientHeight;  
        
    if (isNearBottom) {    
      chatContainer.scrollTop = chatContainer.scrollHeight;    
    }    
  }    
}  
  


  function processMessage() {
    let convId = $chosenConversationId;
    routeMessage(input, convId);
    input = ""; 
  }
  function scrollChat() {
    if (chatContainer) chatContainer.scrollTop = chatContainer.scrollHeight;
  }

  let lastMessageCount = 0; 
  afterUpdate(() => {
    const currentMessageCount = $conversations[$chosenConversationId]?.history.length || 0;
    if (currentMessageCount > lastMessageCount) {
      scrollChat();
    }
    lastMessageCount = currentMessageCount; // Update the count after every update
  });
  
  $: isVisionMode = $selectedMode.includes('Vision');

$: conversationTitle = $conversations[$chosenConversationId] ? $conversations[$chosenConversationId].title : "ChatGPT";


let uploadedFileCount: number = 0; // New variable to track the number of files uploaded
$: uploadedFileCount = $base64Images.length;

</script>
<title>
  {#if $conversations.length > 0 && $conversations[$chosenConversationId]}
  {$conversations[$chosenConversationId].title || "ChatGPT API"}
{:else}
  ChatGPT API
{/if}
</title>
{#if $settingsVisible}
<Settings on:settings-changed={reloadConfig} />
{/if}

<main class="bg-primary overflow-hidden">
  <Sidebar on:new-chat={() => newChat()} />
    <div class="h-screen flex flex-col md:ml-[260px] bg-secondary text-white/80 height-manager">
      <Topbar bind:conversation_title={conversationTitle} on:new-chat={newChat} />

      <div class="flex-1 bg-primary overflow-y-auto overflow-x-hidden" bind:this={chatContainer}>
      {#if $conversations.length > 0 && $conversations[$chosenConversationId]}
        <div class="flex flex-col">
          {#each $conversations[$chosenConversationId].history as message, i}
            <div class="message relative inline-block {message.role === 'assistant' ? 'bg-hover2' : 'bg-primary'} px-2 py-5">
              <button class="copyButton" on:click={() => copyTextToClipboard(message.content)}>
                <img class="icon-white w-8" alt="Copy" src={CopyIcon} />
              </button>
              <button class="deleteButton" on:click={() => deleteMessageFromConversation(i)}>
                <img class="icon-white w-8" alt="Delete" src={DeleteIcon} />
              </button>
              <div class="px-20 text-[1rem]">
                {#if isAudioMessage(message)}
                  <AudioPlayer audioUrl={message.audioUrl} />
                {:else}
                  <SvelteMarkdown renderers={{
                    code: CodeRenderer,
                    em: EmRenderer,
                    list: ListRenderer,
                    listitem: ListItemRenderer,
                    codespan: CodeSpanRenderer,
                    paragraph: ParagraphRenderer,
                    html: HtmlRenderer,
                  }} source={formatMessageForMarkdown(message.content.toString())} />
                {/if}
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="flex justify-center items-center h-full">
          <p>No conversation selected. Start a new conversation.</p>
        </div>
      {/if}
    </div>
    <div class="flex p-2 bg-primary mt-auto">
      {#if isVisionMode}
      <input type="file" id="imageUpload" multiple accept="image/*" on:change="{handleImageUpload}" bind:this={fileInputElement} class="file-input">
      <label for="imageUpload" class="file-label bg-chat rounded py-2 px-4 mx-1 cursor-pointer hover:bg-hover2 transition-colors">
        {#if uploadedFileCount === 0}
          <img src={UploadIcon} alt="Upload" class="upload-icon icon-white">
        {:else}
          <span class="fileCount">{uploadedFileCount}</span>
        {/if}
      </label>
      {/if}

      <textarea   
  class="w-full min-h-[96px] h-24 rounded p-2 mx-1 mr-0 rounded-r-none bg-chat resize-none focus:outline-none"   
  placeholder="Type your message"   
  bind:value={input}   
  on:keydown={(event) => {  
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);  
    if (!$isStreaming && event.key === "Enter" && !event.shiftKey && !event.ctrlKey && !event.metaKey && !isMobile) {  
      event.preventDefault(); // Prevent default insert line break behavior  
      processMessage();  
    }  
    else if (!$isStreaming && event.key === "Enter" && isMobile) {  
      // Allow default behavior on mobile, which is to insert a new line  
      // Optionally, you can explicitly handle mobile enter key behavior here if needed  
    }  
  }}  
></textarea>  
<button class="bg-chat rounded py-2 px-4 mx-1 ml-0 rounded-l-none" on:click={() => { if ($isStreaming) { closeStream(); } else { processMessage(); } }} disabled={!$isStreaming && !input.trim().length}>    
  {#if $isStreaming}    
      <img class="icon-white min-w-[24px] w-[24px]" alt="Wait" src={WaitIcon} />    
  {:else}    
      <img class="icon-white min-w-[24px] w-[24px]" alt="Send" src={SendIcon} />    
  {/if}    
</button>  
     
    </div>
  </div>
</main>

<style>
  @import './styles/styles.css';
</style>