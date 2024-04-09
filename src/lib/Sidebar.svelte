<script lang="ts">
  import { createEventDispatcher } from "svelte";
  import {
    settingsVisible,
    conversations,
    chosenConversationId,
    menuVisible,
    apiKey,
    defaultAssistantRole,
    type Conversation,
    type DefaultAssistantRole,
    selectedModel,
  } from "../stores/stores";
  import CloseIcon from "../assets/close.svg";
  import EditIcon from "../assets/edit.svg"; // Make sure you have an Edit icon

  const dispatch = createEventDispatcher();
  let placeholder = `Using: Svelte, Typescript.
OR
You are a therapist. ETC...`;

  function newChat() {
    dispatch("new-chat");
  }

  function openSettings() {
    settingsVisible.set(true);
  }

  async function deleteConversation(i: number) {
  console.log("Attempting to delete conversation at index:", i);

  // Check if there's only one conversation in the list
  if ($conversations.length <= 1) {
    console.log("Deletion aborted: Cannot delete the last conversation.");
    return; // Abort deletion if it's the last conversation
  }

  let conv = $conversations.filter((value, index) => index !== i);
  console.log("Updated conversations list after deletion attempt:", conv);

  // Adjust the selected conversation index if necessary
  if (i === $chosenConversationId) {
    // If deleting the current conversation, switch to another conversation (preceding one if possible)
    chosenConversationId.set(i > 0 ? i - 1 : 0);
    console.log("Selected conversation index adjusted to:", i > 0 ? i - 1 : 0);
  } else if (i < $chosenConversationId) {
    // If deleting a conversation before the current one, adjust the index of the selected conversation
    chosenConversationId.set($chosenConversationId - 1);
    console.log("Selected conversation index adjusted due to deletion before it. New index:", $chosenConversationId - 1);
  }

  conversations.set(conv); // Update the conversations list
}
let editingTitleId = null;
  let editedTitle = "";

  // Function to handle starting the edit of a conversation title
  function startEditConversationTitle(id: number, title: string) {
  editingTitleId = id;
  editedTitle = title;
}


  // Function to handle saving the edited conversation title
  function saveEditedTitle(id: number) {
    conversations.update((allConvs) => {
      let convs = [...allConvs];
      convs[id].title = editedTitle;
      return convs;
    });
    editingTitleId = null; // Reset editing state
  }
</script>

<div class="flex flex-col text-white/90">
  <div class="{$menuVisible == true ? 'translate-x-0' : '-translate-x-[100%] md:translate-x-0'} duration-200 h-full fixed md:flex w-[260px] flex-col bg-secondary">
    <nav class="flex h-full fle-1 flex-col space-y-1 p-2 bg-secondary">
      <button on:click={() => {menuVisible.set(false);}} class="md:hidden flex py-3 px-3 items-center gap-3 rounded-md hover:bg-hover hover:opacity-hover transition-colors duration-200 cursor-pointer text-sm mb-2 flex-shrink-0 border border-white/50">
        Close menu
      </button>
      <button on:click={newChat} class="flex py-3 px-3 items-center gap-3 rounded-md hover:bg-hover transition-colors duration-200 cursor-pointer text-sm mb-2 flex-shrink-0 border border-white/50">
        New chat
      </button>
      <div class="py-1 select-none">
        <p class="text-center px-8 font-bold text-2xl">ChatGPT API<br /></p>
        <p class="text-center font-bold text-l leading-4 pb-2">Model: {$selectedModel}</p> <!-- Added line -->
        <p class="text-center font-bold text-l leading-4 pb-2">System Role:</p>
      </div>
      {#if $conversations[$chosenConversationId]}
      <textarea bind:value={$conversations[$chosenConversationId].assistantRole} {placeholder} class="bg-primary px-2 pt-1 pb-3 resize-none rounded focus:outline-none focus:outline-primary"></textarea>
      {:else}
      <textarea placeholder="Select a conversation or start a new one..." class="bg-primary px-2 pt-1 pb-3 resize-none rounded focus:outline-none focus:outline-primary"></textarea>
      {/if}
      
        <div class="flex flex-col h-40 my-2 flex-grow overflow-y-auto ">
          <!-- Conversation listing starts here -->
          {#each $conversations.slice().reverse() as conv, i}
          <div class="{$chosenConversationId === $conversations.length - i - 1 ? 'bg-hover2 hover:bg-hover2' : ''} conversation flex justify-between min-h-[64px] my-2 py-3 px-3 items-center gap-3 rounded-md hover:bg-hover cursor-pointer text-sm transition-colors duration-200" tabindex="-1" on:click={() => {let id = $conversations.length - i - 1; chosenConversationId.set(id);}} on:keydown={(e) => {if (e.key === 'Enter' || e.key === ' ') {e.preventDefault(); let id = $conversations.length - i - 1; chosenConversationId.set(id);}}} >
            {#if editingTitleId === $conversations.length - i - 1}
              <input type="text"  class="edit-input" bind:value={editedTitle} on:blur={() => saveEditedTitle($conversations.length - i - 1)} on:keydown={(e) => {if (e.key === 'Enter') {saveEditedTitle($conversations.length - i - 1); e.preventDefault();}}}/>
            {:else}
              <p class="text-left text-sm max-w-[178px] flex-grow">
                {conv.title === "" ? "New conversation" : conv.title}
              </p>
            {/if}
            <div class="flex items-center gap-2">
              <button tabindex="0" on:click|stopPropagation={(e) => {let id = $conversations.length - i - 1; startEditConversationTitle(id, conv.title);}} on:keydown|stopPropagation={(e) => {if (e.key === 'Enter' || e.key === ' ') {e.preventDefault(); let id = $conversations.length - i - 1; startEditConversationTitle(id, conv.title);}}} class="edit hidden rounded w-5 h-5 font-bold flex justify-center items-center bg-primary">
                <img src={EditIcon} alt="Edit" class="icon-white min-w-3 w-3 h-3"/>
              </button>
              <button tabindex="0" on:click|stopPropagation={(e) => {let id = $conversations.length - i - 1; deleteConversation(id);}} on:keydown|stopPropagation={(e) => {if (e.key === 'Enter' || e.key === ' ') {e.preventDefault(); let id = $conversations.length - i - 1; deleteConversation(id);}}} class="delete hidden rounded w-5 h-5 font-bold flex justify-center items-center bg-warning">
                <img src={CloseIcon} alt="Delete" class="icon-white min-w-3 w-3 h-3"/>
              </button>
            </div>
            <p class="text-blue-200 tokens">
              {conv.conversationTokens.toFixed(0)}
            </p>
          </div>
          {/each}
        </div>
      <button on:click={openSettings} class="flex border border-white/50 py-3 px-3 items-center font-bold gap-3 rounded-md hover:bg-hover transition-colors duration-200 cursor-pointer text-sm mt-auto">
        Settings {$apiKey === null ? "(Insert API key)" : ""}
      </button>
    </nav>
  </div>
</div>



<style>
  * {
    z-index: 1;
  }

.conversation .edit,
.conversation .delete {
  display: none;
}

.conversation:hover .tokens {
  display: none;
}
.conversation:hover .edit,
.conversation:hover .delete {
  display: flex;
}
.edit-input {
  background-color: #333; /* Dark gray background */
  color: white; /* Light text color for visibility */
  width: auto; /* Adjust width as needed */
  max-width: 145px; /* Maximum width to fit the sidebar */
  padding: 8px; /* Padding for aesthetics */
  border-radius: 4px; /* Optional: rounded corners */
  border: 1px solid #555; /* Slightly lighter border for some depth */
}

</style>
