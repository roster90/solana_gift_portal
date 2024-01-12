use anchor_lang::prelude::*;
use anchor_lang::solana_program::entrypoint::ProgramResult;

// use anchor_lang::solana_program::msg;

declare_id!("5tzyMy3NYB8C93QircdAPEf1QP7GDFWRZ9K8D6imbivx");

#[program]
pub mod gifportal {

    use super::*;

    pub fn start_stuff_off(ctx: Context<StartStuffOff>) -> ProgramResult{
        let base_account = &mut ctx.accounts.base_account;
        base_account.total_gifts = 0;
        Ok(())
    }

    pub fn add_gift(ctx: Context<AddGift>, gift_link: String) -> ProgramResult {
        let base_account = &mut ctx.accounts.base_account;
   
        let user = &mut ctx.accounts.user;

        let item = ItemStruct{
            gift_link: gift_link.to_string(),
            user_address: *user.to_account_info().key
        };
     
        base_account.gift_list.push(item);
        base_account.total_gifts += 1;
        Ok(())
    }

    pub fn send_sol(ctx: Context<SendSol>, amount: u64) -> ProgramResult {
        let ix = anchor_lang::solana_program::system_instruction::transfer(
            &ctx.accounts.from.key(),
            &ctx.accounts.to.key(),
            amount,
        );
        anchor_lang::solana_program::program::invoke(
            &ix,
            &[
                ctx.accounts.from.to_account_info(),
                ctx.accounts.to.to_account_info(),
            ],
        )
    }




}

#[derive(Accounts)]
pub struct StartStuffOff<'info> {
    #[account(init, payer=user, space=9000)]
    pub base_account: Account<'info, BaseAccount>,

    #[account(mut)]
    pub user : Signer<'info>,

    pub system_program: Program<'info, System>

}
#[derive(Accounts)]
pub struct AddGift<'info> {
    #[account(mut)]
    pub base_account: Account<'info, BaseAccount>,
    #[account(mut)]
    pub user: Signer<'info>,

}

#[derive(Accounts)]
pub struct SendSol<'info> {
    #[account(mut)]
    from: Signer<'info>,
    #[account(mut)]
    to: AccountInfo<'info>,
    system_program: Program<'info, System>,
}

#[derive(Debug, Clone, AnchorSerialize, AnchorDeserialize)]
pub struct ItemStruct {
  pub gift_link: String,
  pub user_address: Pubkey
}


#[account]
pub struct BaseAccount {
    pub total_gifts: u64,
    pub gift_list: Vec<ItemStruct>


}

