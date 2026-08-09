import { IsString } from 'class-validator';

export class PresignDto {
  @IsString() domain: string;
  @IsString() fileName: string;
  @IsString() contentType: string;
}
