import { IsString } from 'class-validator';

export class LoginDto {
  @IsString() hallTicket: string;
  @IsString() password: string;
}
