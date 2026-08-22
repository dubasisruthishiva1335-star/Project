import { IsOptional, IsString } from 'class-validator';

export class ConfirmJobListingDto {
  @IsOptional() @IsString() type?: string;
  @IsOptional() @IsString() title?: string;
  @IsOptional() @IsString() company?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() applyUrl?: string;
  @IsOptional() @IsString() deadline?: string;
  @IsOptional() @IsString() branch?: string;
  @IsOptional() @IsString() stipend?: string;
  @IsOptional() @IsString() location?: string;
  @IsOptional() @IsString() s3Key?: string;
  @IsOptional() @IsString() publicUrl?: string;
}
