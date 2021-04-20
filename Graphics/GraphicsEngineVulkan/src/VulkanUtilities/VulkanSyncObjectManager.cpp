/*
 *  Copyright 2019-2021 Diligent Graphics LLC
 *  Copyright 2015-2019 Egor Yusov
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *  In no event and under no legal theory, whether in tort (including negligence), 
 *  contract, or otherwise, unless required by applicable law (such as deliberate 
 *  and grossly negligent acts) or agreed to in writing, shall any Contributor be
 *  liable for any damages, including any direct, indirect, special, incidental, 
 *  or consequential damages of any character arising as a result of this License or 
 *  out of the use or inability to use the software (including but not limited to damages 
 *  for loss of goodwill, work stoppage, computer failure or malfunction, or any and 
 *  all other commercial damages or losses), even if such Contributor has been advised 
 *  of the possibility of such damages.
 */

#include "VulkanUtilities/VulkanSyncObjectManager.hpp"

namespace VulkanUtilities
{

VulkanSyncObjectManager::VulkanSyncObjectManager(VulkanLogicalDevice& LogicalDevice) :
    m_LogicalDevice{LogicalDevice}
{
    m_SemaphorePool.reserve(64);
}

VulkanSyncObjectManager::~VulkanSyncObjectManager()
{
    {
        std::lock_guard<std::mutex> Lock{m_SemaphorePoolGuard};

        for (auto vkSem : m_SemaphorePool)
        {
            vkDestroySemaphore(m_LogicalDevice.GetVkDevice(), vkSem, nullptr);
        }
    }
    {
        std::lock_guard<std::mutex> Lock{m_FencePoolGuard};

        for (auto vkFence : m_FencePool)
        {
            vkDestroyFence(m_LogicalDevice.GetVkDevice(), vkFence, nullptr);
        }
    }
}

void VulkanSyncObjectManager::CreateSemaphores(VulkanRecycledSemaphore* pSemaphores, uint32_t Count)
{
    uint32_t i = 0;
    {
        std::lock_guard<std::mutex> Lock{m_SemaphorePoolGuard};

        const uint32_t NumSemInPool = std::min(static_cast<uint32_t>(m_SemaphorePool.size()), Count);

        for (size_t p = m_SemaphorePool.size() - NumSemInPool; p < m_SemaphorePool.size(); ++i, ++p)
        {
            pSemaphores[i] = VulkanRecycledSemaphore{shared_from_this(), m_SemaphorePool[p]};
        }
        m_SemaphorePool.erase(m_SemaphorePool.end() - NumSemInPool, m_SemaphorePool.end());
    }

    // Create new semaphores.
    VkSemaphoreCreateInfo SemCI = {VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO};

    for (; i < Count; ++i)
    {
        VkSemaphore vkSem = VK_NULL_HANDLE;
        vkCreateSemaphore(m_LogicalDevice.GetVkDevice(), &SemCI, nullptr, &vkSem);

        pSemaphores[i] = VulkanRecycledSemaphore{shared_from_this(), vkSem};
    }
}

VulkanRecycledFence VulkanSyncObjectManager::CreateFence()
{
    {
        std::lock_guard<std::mutex> Lock{m_FencePoolGuard};

        if (!m_FencePool.empty())
        {
            auto vkFence = m_FencePool.back();
            m_FencePool.pop_back();
            return VulkanRecycledFence{shared_from_this(), vkFence};
        }
    }

    VkFenceCreateInfo FenceCI = {VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
    VkFence           vkFence = VK_NULL_HANDLE;

    vkCreateFence(m_LogicalDevice.GetVkDevice(), &FenceCI, nullptr, &vkFence);

    return VulkanRecycledFence{shared_from_this(), vkFence};
}

void VulkanSyncObjectManager::Recycle(VkSemaphore vkSem, bool IsUnsignaled)
{
    // Can not reuse semaphore in signaled state
    if (!IsUnsignaled)
    {
        vkDestroySemaphore(m_LogicalDevice.GetVkDevice(), vkSem, nullptr);
        return;
    }

    std::lock_guard<std::mutex> Lock{m_SemaphorePoolGuard};
    m_SemaphorePool.push_back(vkSem);
}

void VulkanSyncObjectManager::Recycle(VkFence vkFence, bool IsUnsignaled)
{
    if (!IsUnsignaled)
    {
        // Acces to vkFence must be externally synchronized, we assume that vkFence is not used anywhere else.
        vkResetFences(m_LogicalDevice.GetVkDevice(), 1, &vkFence);
    }

    std::lock_guard<std::mutex> Lock{m_FencePoolGuard};
    m_FencePool.push_back(vkFence);
}

} // namespace VulkanUtilities
