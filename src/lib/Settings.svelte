<script lang="ts">
    import { selectedModel, selectedVoice, selectedMode } from '../stores/stores';
    import { createEventDispatcher } from 'svelte';
    import CloseIcon from "../assets/close.svg";
    import { writable, get, derived } from "svelte/store";
  import { onMount } from 'svelte';

  import {
    apiKey,
    settingsVisible,
    combinedTokens,
    defaultAssistantRole,
    type DefaultAssistantRole,
  } from "../stores/stores";

  const dispatch = createEventDispatcher();

  let apiCheckMessage = writable('');
  let models = writable([]); // Store for available models
  let filteredModels = writable([]); // Initialize filteredModels as a writable store
  $: $selectedMode, updateFilteredModels();
    $: $models, updateFilteredModels();

  let localApiTextField: string = get(apiKey) || ''; 
  $: localApiTextField = $apiKey || '';

  let apiTextField = '';
  apiKey.subscribe(value => {
    apiTextField = value || '';
    localApiTextField = apiTextField;
  });

  let assistantRoleField = $defaultAssistantRole.role;
  let assistantRoleTypeField = $defaultAssistantRole.type;

  apiKey.subscribe((value) => {
  localStorage.setItem("api_key", JSON.stringify(value));
});


onMount(async() => {
   await initializeSettings();

  });

 function updateFilteredModels() {
        let mode = get(selectedMode);
        let availableModels = get(models);
        let newFilteredModels = [];

        if (mode === "GPT") {
            newFilteredModels = availableModels.filter(model => model.id.includes('gpt') && !model.id.includes('vision'));
        } else if (mode === "GPT + Vision") {
            newFilteredModels = availableModels.filter(model => model.id.includes('vision'));
        } else if (mode === "TTS") {
            newFilteredModels = availableModels.filter(model => model.id.includes('tts'));
        }

        filteredModels.set(newFilteredModels);

        // Automatically select the first model in the filtered list if the current selection is not in the new list
        if (newFilteredModels.length > 0 && (!get(selectedModel) || !newFilteredModels.some(model => model.id === get(selectedModel)))) {
            selectedModel.set(newFilteredModels[0].id);
        }
    }
async function initializeSettings() {
    const savedMode = localStorage.getItem("selectedMode");
    selectedMode.set(savedMode || "GPT"); 

    if (apiTextField) {
        await fetchModels(apiTextField);
    } else {
        const savedModels = localStorage.getItem("models");
        if (savedModels) {
            models.set(JSON.parse(savedModels));
        }
    }
    updateFilteredModels(); 
}

async function checkAPIConnection() {
  if (!localApiTextField) {
    apiCheckMessage.set("API key is missing.");
    return;
  }

  try {
    const response = await fetch('https://api.openai.com/v1/models', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${localApiTextField}`,
        'Content-Type': 'application/json'
      },
    });

    if (response.ok) {
      apiCheckMessage.set("API connection succeeded.");
      // Optionally, reload settings or models here
      handleSave();
      await fetchModels(apiTextField);
      updateFilteredModels(); 
    } else {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
  } catch (error) {
    console.error("API connection failed:", error);
    apiCheckMessage.set("API connection failed.");
  }
}



async function fetchModels(apiKey: string) {
  if (!apiKey) {
    console.error("API key is missing.");
    return;
  }

  try {
    const response = await fetch('https://api.openai.com/v1/models', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    const sortedModels = data.data.sort((a, b) => a.id.localeCompare(b.id));
    models.set(sortedModels);
    localStorage.setItem("models", JSON.stringify(sortedModels));

    // After models are fetched and set, restore the model selection
  } catch (error) {
    console.error("Failed to fetch models:", error);
  }
}

  function clearTokens() {
    combinedTokens.set(0);
  }

  function handleSave() {
  defaultAssistantRole.set({ role: assistantRoleField, type: assistantRoleTypeField });
  apiKey.set(localApiTextField);

  localStorage.setItem('selectedModel', get(selectedModel));
  localStorage.setItem('selectedVoice', get(selectedVoice));
  localStorage.setItem('selectedMode', get(selectedMode));

  dispatch('settings-changed');
  console.log("Settings saved.");
  }





  function handleClose() {
    settingsVisible.set(false);
  }

  function handleSaveAndClose() {
handleSave();
handleClose();
  }

</script>

<!-- Settings.svelte -->
<div class="fixed z-10 inset-0  overflow-y-auto animate-fade-in">
  <div class="flex items-center  justify-center min-h-screen">
    <div class="bg-primary text-white rounded-lg shadow-xl p-8 relative">
      <button
        class="absolute top-0 right-0 mt-2 mr-2 text-gray-500 hover:text-gray-600"
        on:click={handleClose}
      >
        <img class="icon-white w-8" alt="Close" src={CloseIcon} />
      </button>
      <h2 class="text-xl font-bold mb-4">Settings</h2>
    <div class="mb-4">
  <label for="api-key" class="block font-medium mb-2">API Key</label>
  <div class="flex items-center">
    <input
      type="password"
      id="api-key"
      name="api-key"
      class="border text-black border-gray-300 p-2 rounded w-full"
      bind:value={localApiTextField}
    />
    <button
      class="ml-2 bg-info hover:bg-infoHover text-white p-2 rounded"
      on:click={checkAPIConnection}
    >Check API</button>
  </div>
  <p class="mt-2">{ $apiCheckMessage }</p>
</div>


      <div class="mb-4">
        <label for="mode-selection" class="block font-medium mb-2">Mode Selection</label>
        <select bind:value={$selectedMode} class="border text-black border-gray-300 p-2 rounded w-full" id="mode-selection">
          <option value="GPT">GPT</option>
          <option value="GPT + Vision">GPT + Vision</option>
          <option value="TTS">TTS</option>
        </select>
      </div>
      

      <div class="mb-4">
        <label for="model-selection" class="block font-medium mb-2">Model Selection</label>
       <select bind:value={$selectedModel} class="border text-black border-gray-300 p-2 rounded w-full" id="model-selection">
    {#each $filteredModels as model}
        <option value={model.id}>{model.id}</option>
    {/each}
</select>
      </div>
      {#if $selectedModel.startsWith('tts')}
<div class="mb-4">
  <label for="voice-selection" class="block font-medium mb-2">Voice Selection</label>
  <select bind:value={$selectedVoice} class="border text-black border-gray-300 p-2 rounded w-full" id="voice-selection">
    <option value="alloy">Alloy</option>
    <option value="echo">Echo</option>
    <option value="fable">Fable</option>
    <option value="onyx">Onyx</option>
    <option value="nova">Nova</option>
    <option value="shimmer">Shimmer</option>
  </select>
</div>
{/if}
      <div class="mb-4">
        <label for="api-key" class="block font-medium mb-2"
          >Default Assistant role</label
        >
        <input
          class="border text-black border-gray-300 p-2 rounded w-full"
          bind:value={assistantRoleField}
        />
        <select
          bind:value={assistantRoleTypeField}
          class="max-w-[86px] text-black bg-white my-2 p-2 rounded focus:outline-none focus:bg-white "
        >
          <option value="system">System</option>
          <option value="user">User</option>
        </select>
      </div>
      <div class="mb-4 flex justify-between items-center ">
        <p class="block font-bold">
          Tokens spent: {$combinedTokens.toFixed(0)} | {(
            ($combinedTokens / 1000) *
            0.002
          ).toFixed(4)} $
        </p>
        <button
          on:click={clearTokens}
          class="bg-warning hover:bg-warningHover transition-colors duration-200 text-white ml-10 w-5 h-5 flex align-middle justify-center rounded"
          style="font-size: 1rem"
        >
          <img class="icon-white w-3" alt="Close" src={CloseIcon} />
        </button>
      </div>
      <button
        class="bg-good hover:bg-good2 transition-colors duration-200 text-white py-2 px-4 rounded"
        on:click={handleSaveAndClose}>Save</button
      >
    </div>
  </div>
</div>

<style>
  @import '../styles/settings.css';
 
</style>
